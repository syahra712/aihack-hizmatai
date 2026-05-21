"""
HizmatAI — Google ADK (Antigravity) Orchestrator
=================================================
This module is the CORE of the system. Google ADK orchestrates ALL agent
workflows: the Gemini LLM decides which tools to call, in what order,
and generates human-readable reasoning at each step.

Architecture:
  User Input → Gemini Orchestrator → [Tool Calls] → Response + Trace
                    ↓
         parse_intent()        → extract service, zone, urgency
         discover_providers()  → find matching providers in zone
         rank_providers()      → score by distance/rating/reliability
         calculate_price()     → dynamic PKR quote
         create_booking()      → confirm slot, guard double-booking
         schedule_followup()   → reminders, status updates

Each tool call is captured as a trace step for the AgentTracePanel.
"""

import json
import os
import asyncio
from contextvars import ContextVar
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai.types import Content, Part

from agents import (
    run_intent_agent,
    run_rank_agent,
    run_price_agent,
    run_booking_agent,
    run_followup_agent,
    refresh_provider_slots,
)

# ─── Load provider dataset ──────────────────────────────────
_providers: list[dict] = json.loads(
    (Path(__file__).parent / "providers.json").read_text()
)
refresh_provider_slots(_providers)

# ─── Per-session state (replaces old module-level globals) ───
_sessions: dict[str, dict] = {}


def _get_session_state(session_id: str) -> dict:
    if session_id not in _sessions:
        _sessions[session_id] = {
            "trace": [],
            "last_intent": {},
            "last_ranked": [],
            "last_booking": {},
        }
    return _sessions[session_id]


_current_ctx: ContextVar[dict] = ContextVar("_current_ctx")


def _ctx() -> dict:
    return _current_ctx.get()


def _add_trace(ctx: dict, agent: str, step: str, input_data: Any, output_data: Any, reasoning: str):
    ctx["trace"].append({
        "agent": agent,
        "step": step,
        "input": input_data,
        "output": output_data,
        "reasoning": reasoning,
        "timestamp": datetime.utcnow().isoformat(),
    })


# ═══════════════════════════════════════════════════════════════
# ADK TOOL FUNCTIONS — Each wraps an existing agent as a callable tool
# Gemini decides when and how to call these based on user input
# ═══════════════════════════════════════════════════════════════

def parse_intent(user_text: str) -> dict:
    """Parse a user's home service request written in Urdu, Roman Urdu, or English.
    Extracts the service type (electrician, plumber, ac_repair, cleaner, beautician, home_tutor),
    the location/zone, and whether the request is urgent.
    Call this FIRST for every new user request."""
    ctx = _ctx()
    ctx["trace"].clear()

    result = run_intent_agent(user_text)
    intent = result["intent"]
    ctx["last_intent"] = intent

    for t in result["trace"]:
        _add_trace(ctx, t["agent"], t["step"], t["input"], t["output"], t["reasoning"])

    return {
        "service_type": intent.get("service_type"),
        "zone": intent.get("zone"),
        "is_urgent": intent.get("is_urgent", False),
        "ambiguous": intent.get("ambiguous", False),
        "clarification_question": intent.get("clarification_question"),
    }


def discover_providers(service_type: str, zone: str) -> dict:
    """Find available service providers that match the given service type and zone.
    Returns a list of providers with their details. Call this AFTER parse_intent."""
    ctx = _ctx()
    matched = [
        p for p in _providers
        if p["service_type"] == service_type and p["is_available"]
    ]

    zone_matched = [p for p in matched if p["zone"] == zone]
    scenario_b = len(zone_matched) == 0

    if scenario_b and matched:
        _add_trace(
            ctx, "DiscoveryAgent", "zone_fallback",
            {"zone": zone, "service_type": service_type},
            {"zone_match": 0, "total_available": len(matched)},
            f"No providers in '{zone}'. Falling back to all available '{service_type}' providers across zones."
        )
        result_providers = matched[:5]
    else:
        result_providers = zone_matched if zone_matched else matched[:5]

    _add_trace(
        ctx, "DiscoveryAgent", "provider_search",
        {"service_type": service_type, "zone": zone},
        {"providers_found": len(result_providers), "names": [p["name"] for p in result_providers[:3]]},
        f"Found {len(result_providers)} available providers for '{service_type}' in/near '{zone}'"
    )

    return {
        "providers_found": len(result_providers),
        "scenario_b_no_zone_match": scenario_b,
        "top_providers": [
            {"id": p["id"], "name": p["name"], "zone": p["zone"], "rating": p["rating"]}
            for p in result_providers[:5]
        ],
    }


def rank_providers(service_type: str, user_lat: float, user_lng: float) -> dict:
    """Rank available providers using weighted scoring: distance (20%), rating (25%),
    reliability (20%), specialization (15%), price (10%), cancellation rate (10%).
    Call this AFTER discover_providers to get the best matches sorted by score."""
    ctx = _ctx()

    result = run_rank_agent(
        providers=_providers,
        user_lat=user_lat,
        user_lng=user_lng,
        service_type=service_type,
    )

    ctx["last_ranked"] = result["ranked"]

    for t in result["trace"]:
        _add_trace(ctx, t["agent"], t["step"], t["input"], t["output"], t["reasoning"])

    top3 = result["ranked"][:3]
    return {
        "top_3_providers": [
            {
                "id": p["id"],
                "name": p["name"],
                "score": p["score"],
                "rating": p["rating"],
                "distance_km": p["distance_km"],
                "hourly_rate": p["hourly_rate"],
                "why_chosen": p.get("why_chosen", "best match"),
            }
            for p in top3
        ],
        "total_ranked": len(result["ranked"]),
    }


def calculate_price(provider_id: str, estimated_hours: float, is_urgent: bool, distance_km: float) -> dict:
    """Calculate a dynamic PKR price quote for a specific provider.
    Includes base rate, urgency surcharge, distance fee, peak-hour surge, and loyalty discount.
    Call this AFTER rank_providers to get cost estimate for the recommended provider."""
    ctx = _ctx()
    provider = next((p for p in _providers if p["id"] == provider_id), None)
    if not provider:
        if ctx["last_ranked"]:
            provider = ctx["last_ranked"][0]
            _add_trace(ctx, "PriceAgent", "provider_id_fallback",
                {"requested_id": provider_id},
                {"fallback_to": provider["id"]},
                f"Provider '{provider_id}' not found. Falling back to top-ranked provider '{provider['name']}'.")
        else:
            return {"error": f"Provider '{provider_id}' not found and no ranked providers available."}

    result = run_price_agent(
        provider=provider,
        hours=estimated_hours,
        is_urgent=is_urgent,
        distance_km=distance_km,
    )

    for t in result["trace"]:
        _add_trace(ctx, t["agent"], t["step"], t["input"], t["output"], t["reasoning"])

    bd = result["breakdown"]
    return {
        "provider_id": provider_id,
        "provider_name": provider["name"],
        "base": bd["base"],
        "urgency_fee": bd["urgency_fee"],
        "distance_fee": bd["distance_fee"],
        "surge_fee": bd["surge_fee"],
        "discount": bd["discount"],
        "total_pkr": bd["total"],
        "estimated_hours": bd["hours_estimated"],
    }


def create_booking(provider_id: str, slot: str, service_type: str, total_price: int) -> dict:
    """Confirm a booking with a specific provider at a given time slot.
    Checks for double-booking conflicts before confirming.
    Returns a booking reference number on success.
    Call this AFTER calculate_price to finalize the booking."""
    ctx = _ctx()

    provider = next((p for p in _providers if p["id"] == provider_id), None)
    if not provider:
        if ctx["last_ranked"]:
            provider = ctx["last_ranked"][0]
            _add_trace(ctx, "BookingAgent", "provider_id_fallback",
                {"requested_id": provider_id},
                {"fallback_to": provider["id"]},
                f"Provider '{provider_id}' not found. Falling back to top-ranked provider '{provider['name']}'.")
        else:
            return {"error": f"Provider '{provider_id}' not found and no ranked providers available."}

    result = run_booking_agent(
        provider=provider,
        slot=slot,
        user_id="demo_user",
        service_type=service_type,
        price_breakdown={"total": total_price},
    )

    for t in result["trace"]:
        _add_trace(ctx, t["agent"], t["step"], t["input"], t["output"], t["reasoning"])

    if result["success"]:
        ctx["last_booking"] = result["booking"]
        return {
            "success": True,
            "booking_ref": result["booking"]["ref"],
            "provider_name": result["booking"]["provider_name"],
            "slot": slot,
            "status": "confirmed",
            "message": f"Booking confirmed! Ref: {result['booking']['ref']}. Provider {provider['name']} will arrive at the scheduled time.",
        }
    else:
        return {
            "success": False,
            "error": result.get("error"),
            "message": result.get("message"),
            "next_available_slots": result.get("next_slots", []),
        }


def schedule_followup(booking_ref: str, followup_type: str) -> dict:
    """Schedule post-booking follow-up actions such as reminders, status updates, or cancellations.
    followup_type can be: 'reminder', 'status_update', 'cancel_by_provider', or 'dispute'.
    Call this AFTER create_booking to set up automated follow-ups."""
    ctx = _ctx()
    real_ref = booking_ref
    last_booking = ctx["last_booking"]
    if last_booking:
        from agents import _bookings_db
        if not any(b["ref"] == booking_ref for b in _bookings_db):
            real_ref = last_booking.get("ref", booking_ref)

    action_map = {
        "reminder": "status_update",
        "status_update": "status_update",
        "cancel_by_provider": "cancel_by_provider",
        "dispute": "dispute",
    }
    action = action_map.get(followup_type, "status_update")

    payload = {}
    if action == "status_update":
        payload = {"status": "reminder_sent"}
    elif action == "dispute":
        payload = {"complaint": "Service quality issue"}

    result = run_followup_agent(
        booking_ref=real_ref,
        action=action,
        payload=payload,
    )

    for t in result["trace"]:
        _add_trace(ctx, t["agent"], t["step"], t["input"], t["output"], t["reasoning"])

    _add_trace(
        ctx, "FollowupAgent", "reminder_scheduled",
        {"booking_ref": booking_ref, "type": followup_type},
        {"scheduled": True},
        f"Automated {followup_type} scheduled. WhatsApp notification will be sent 1 hour before appointment."
    )

    return {
        "success": result.get("success", True),
        "action": followup_type,
        "message": f"Follow-up '{followup_type}' scheduled for booking {booking_ref}. "
                   f"User will receive WhatsApp reminder 1 hour before the appointment.",
    }


# ═══════════════════════════════════════════════════════════════
# ADK AGENT DEFINITION — Google Antigravity Orchestrator
# Gemini LLM decides the workflow, tool sequence, and reasoning
# ═══════════════════════════════════════════════════════════════

ORCHESTRATOR_INSTRUCTION = """You are HizmatAI, an intelligent agentic system that automates home service booking in Pakistan.
You help users find and book service providers (electricians, plumbers, AC technicians, cleaners, beauticians, home tutors) through natural conversation.

You understand Urdu, Roman Urdu, and English. Users from Karachi, Lahore, and Islamabad use your service.

## YOUR WORKFLOW (follow this pipeline for every service request):

1. **ALWAYS call `parse_intent` first** with the user's raw text to extract service type, zone, and urgency.

2. If the intent is ambiguous (no clear service type), ask the user for clarification using the clarification_question from parse_intent.

3. **Call `discover_providers`** with the detected service_type and zone to find available providers.

4. **Call `rank_providers`** with service_type and Karachi coordinates (lat=24.8040, lng=67.0708) to get the best providers ranked by score.

5. **Call `calculate_price`** for the TOP ranked provider. Use estimated_hours=2.0, and pass is_urgent and distance_km from previous steps.

6. **Call `create_booking`** for the top provider. Use the first available slot from the provider data. Pass the total_price from calculate_price.

7. **Call `schedule_followup`** with the booking reference and followup_type="reminder" to set up automated reminders.

## RESPONSE FORMAT:
After completing all steps, provide a clear summary in the SAME LANGUAGE the user used:
- If user wrote in Roman Urdu → respond in Roman Urdu
- If user wrote in Urdu script → respond in Urdu script
- If user wrote in English → respond in English
- If mixed → respond in Roman Urdu

Include: service type, recommended provider name, why they were chosen, price, booking confirmation, and follow-up details.

## IMPORTANT RULES:
- ALWAYS execute the full pipeline (all 6 tools) for a complete service request
- Show your reasoning at each step
- If a booking fails (double-booking), explain and suggest alternatives
- Be friendly and conversational like a helpful Pakistani assistant
- Use "Aap", not "tum" — respectful tone always
- Be concise. Never repeat the same sentence or fact twice in your response.
"""

def _build_model():
    groq_key = os.environ.get("GROQ_API_KEY")
    gemini_key = os.environ.get("GOOGLE_API_KEY")
    if groq_key:
        return LiteLlm(model="groq/llama-3.1-8b-instant")
    if gemini_key:
        return os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")
    raise RuntimeError("No API key found. Set GROQ_API_KEY or GOOGLE_API_KEY in .env")

# Create the root orchestrator agent
orchestrator_agent = LlmAgent(
    name="hizmat_orchestrator",
    model=_build_model(),
    instruction=ORCHESTRATOR_INSTRUCTION,
    tools=[
        parse_intent,
        discover_providers,
        rank_providers,
        calculate_price,
        create_booking,
        schedule_followup,
    ],
)

# Session management
_session_service = InMemorySessionService()
_runner = Runner(
    agent=orchestrator_agent,
    app_name="hizmat_ai",
    session_service=_session_service,
)


# ═══════════════════════════════════════════════════════════════
# PUBLIC API — Called by FastAPI endpoints
# ═══════════════════════════════════════════════════════════════

async def run_orchestrator(user_text: str, user_id: str = "demo_user", session_id: str = None) -> dict:
    """
    Main entry point: sends user text to the Google ADK orchestrator.
    Gemini decides which tools to call and in what order.
    Returns the final response + complete agent trace.
    Retries up to 3 times on 429/503 errors.
    """
    if session_id is None:
        import uuid
        session_id = f"session_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:6]}"

    last_error = None
    for attempt in range(3):
        try:
            return await _run_orchestrator_once(user_text, user_id, session_id)
        except Exception as e:
            last_error = e
            err_str = str(e)
            import re as _re
            retry_in = None
            _m = _re.search(r'retry in\s+([\d.]+)s', err_str)
            if _m:
                retry_in = float(_m.group(1)) + 1.0
            if "429" in err_str or "503" in err_str or "RESOURCE_EXHAUSTED" in err_str or "UNAVAILABLE" in err_str or "RateLimitError" in err_str or "rate_limit_exceeded" in err_str:
                wait_time = retry_in if retry_in else 5 * (attempt + 1)
                await asyncio.sleep(wait_time)
                continue
            raise
    raise last_error


async def _run_orchestrator_once(user_text: str, user_id: str, session_id: str) -> dict:
    ctx = _get_session_state(session_id)
    _current_ctx.set(ctx)

    session = await _session_service.get_session(
        app_name="hizmat_ai", user_id=user_id, session_id=session_id
    )
    if session is None:
        session = await _session_service.create_session(
            app_name="hizmat_ai", user_id=user_id, session_id=session_id
        )

    message = Content(parts=[Part(text=user_text)])

    final_response = ""
    tool_calls_log = []

    async for event in _runner.run_async(
        user_id=user_id,
        session_id=session_id,
        new_message=message,
    ):
        fn_calls = event.get_function_calls()
        if fn_calls:
            for fc in fn_calls:
                tool_calls_log.append({
                    "tool": fc.name,
                    "args": dict(fc.args) if fc.args else {},
                    "timestamp": datetime.utcnow().isoformat(),
                })

        fn_responses = event.get_function_responses()
        if fn_responses:
            for fr in fn_responses:
                tool_calls_log.append({
                    "tool_response": fr.name,
                    "result_preview": str(fr.response)[:200],
                    "timestamp": datetime.utcnow().isoformat(),
                })

        if event.is_final_response() and event.content and event.content.parts:
            for part in event.content.parts:
                if part.text:
                    final_response += part.text

    # Build the complete trace combining tool calls and agent reasoning
    adk_trace = [{
        "agent": "ADK_Orchestrator",
        "step": "gemini_planning",
        "input": user_text,
        "output": {"tools_called": len(tool_calls_log)},
        "reasoning": "Google ADK Orchestrator (Gemini) analyzed the request and planned the agent pipeline.",
        "timestamp": datetime.utcnow().isoformat(),
    }]

    for tc in tool_calls_log:
        if "tool" in tc:
            adk_trace.append({
                "agent": "ADK_Orchestrator",
                "step": f"tool_call:{tc['tool']}",
                "input": tc.get("args", {}),
                "output": "executed",
                "reasoning": f"Gemini decided to call {tc['tool']} with the extracted parameters.",
                "timestamp": tc["timestamp"],
            })

    # Merge ADK orchestrator trace + individual agent traces
    combined_trace = adk_trace + ctx["trace"]

    return {
        "response": final_response,
        "session_id": session_id,
        "tools_called": [tc.get("tool") for tc in tool_calls_log if "tool" in tc],
        "agent_trace": combined_trace,
        "intent": ctx["last_intent"],
        "ranked_providers": [
            {"id": p["id"], "name": p["name"], "score": p.get("score"), "rating": p["rating"]}
            for p in ctx["last_ranked"][:3]
        ] if ctx["last_ranked"] else [],
        "booking": ctx["last_booking"] if ctx["last_booking"] else None,
    }


def get_session_trace(session_id: str = None) -> list[dict]:
    """Return a session's complete agent trace."""
    if session_id and session_id in _sessions:
        return _sessions[session_id]["trace"].copy()
    return []
