"""
HizmatAI FastAPI Backend — Powered by Google ADK (Antigravity)
==============================================================
The /chat endpoint routes ALL user requests through Google ADK's
Gemini orchestrator, which autonomously decides which agents to invoke.

Direct endpoints (/intent, /rank, /price, /book, /followup) remain
available for granular testing and the Flutter app's step-by-step flow.

Run:  uvicorn main:app --reload --port 8000
"""

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any, Optional, Dict

from dotenv import load_dotenv
load_dotenv()

# Firebase Admin — initialize once (skip if serviceAccountKey.json missing, for local dev)
import firebase_admin
from firebase_admin import credentials as fb_credentials

_service_account_path = Path(__file__).parent / "serviceAccountKey.json"
if _service_account_path.exists() and not firebase_admin._apps:
    _fb_cred = fb_credentials.Certificate(str(_service_account_path))
    firebase_admin.initialize_app(_fb_cred)

import stripe
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from agents import (
    run_intent_agent,
    run_rank_agent,
    run_price_agent,
    run_booking_agent,
    run_followup_agent,
    refresh_provider_slots,
    _bookings_db,
)
from adk_orchestrator import run_orchestrator, get_session_trace

app = FastAPI(
    title="HizmatAI API — Google ADK Orchestrated",
    version="2.0.0",
    description="Agentic home service booking powered by Google Antigravity (ADK)",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Worker routes (requires firebase-admin + serviceAccountKey.json)
try:
    from worker_routes import router as worker_router
    app.include_router(worker_router)
except ImportError:
    pass

# Load provider dataset once at startup
_providers: list[dict] = json.loads(
    (Path(__file__).parent / "providers.json").read_text()
)
refresh_provider_slots(_providers)

# Per-session trace for direct endpoint calls (keyed by session_id)
_direct_traces: Dict[str, list] = {}
_default_trace_key = "__default__"

# ── Multi-turn session memory ────────────────────────────────────
# Keyed by session_id → { service_type, zone, is_urgent, last_booking_ref }
_session_contexts: Dict[str, dict] = {}


def _record_trace(trace_steps: list[dict], session_id: str = None) -> None:
    key = session_id or _default_trace_key
    if key not in _direct_traces:
        _direct_traces[key] = []
    _direct_traces[key].extend(trace_steps)


def _get_ctx(session_id: str | None) -> dict:
    if not session_id:
        return {}
    return _session_contexts.get(session_id, {})


def _save_ctx(session_id: str | None, updates: dict) -> None:
    if not session_id:
        return
    current = _session_contexts.get(session_id, {})
    current.update({k: v for k, v in updates.items() if v is not None})
    _session_contexts[session_id] = current


# ═══════════════════════════════════════════════════════════════
# PRIMARY ENDPOINT — Google ADK Orchestrated Chat
# This is the MAIN endpoint judges should see. Gemini decides
# which agents to call and in what order.
# ═══════════════════════════════════════════════════════════════

class ChatRequest(BaseModel):
    text: str
    user_id: str = "demo_user"
    session_id: Optional[str] = None

@app.post("/chat")
async def chat(req: ChatRequest) -> dict[str, Any]:
    """
    PRIMARY ENDPOINT — Google ADK Orchestrator with direct-pipeline fallback.

    Tries ADK/LLM orchestration first. If the LLM is rate-limited or unavailable,
    automatically runs the 6-agent pipeline directly so the demo never breaks.
    """
    try:
        result = await run_orchestrator(
            user_text=req.text,
            user_id=req.user_id,
            session_id=req.session_id,
        )
        return {
            "success": True,
            "response": result["response"],
            "session_id": result["session_id"],
            "tools_called": result["tools_called"],
            "intent": result["intent"],
            "ranked_providers": result["ranked_providers"],
            "booking": result["booking"],
            "agent_trace": result["agent_trace"],
            "orchestration": "adk_llm",
        }
    except Exception:
        return await _run_direct_pipeline(req.text, req.user_id)


async def _run_direct_pipeline(user_text: str, user_id: str) -> dict[str, Any]:
    """Runs the 6-agent pipeline directly (no LLM orchestration) as a fallback."""
    all_trace: list[dict] = []

    # 1 — Intent
    intent_result = run_intent_agent(user_text)
    all_trace.extend(intent_result["trace"])
    intent = intent_result["intent"]

    if intent.get("ambiguous"):
        return {
            "success": True,
            "response": intent.get("clarification_question", "Could you clarify which service you need?"),
            "intent": intent,
            "ranked_providers": [],
            "booking": None,
            "agent_trace": all_trace,
            "tools_called": ["parse_intent"],
            "orchestration": "direct_pipeline",
        }

    # 2 — Rank
    rank_result = run_rank_agent(
        providers=_providers,
        user_lat=24.8040, user_lng=67.0708,
        service_type=intent["service_type"],
        budget_max=intent.get("budget_max"),
    )
    all_trace.extend(rank_result["trace"])
    ranked = rank_result["ranked"]
    top = ranked[0] if ranked else None

    if not top:
        return {
            "success": True,
            "response": f"Sorry, no {intent['service_type']} providers are available in {intent['zone']} right now.",
            "intent": intent,
            "ranked_providers": [],
            "booking": None,
            "agent_trace": all_trace,
            "tools_called": ["parse_intent", "rank_providers"],
            "orchestration": "direct_pipeline",
        }

    # 3 — Price
    price_result = run_price_agent(
        provider=top,
        hours=2.0,
        is_urgent=intent.get("is_urgent", False),
        distance_km=top.get("distance_km", 3.0),
    )
    all_trace.extend(price_result["trace"])
    bd = price_result["breakdown"]

    # 4 — Booking
    from datetime import timedelta
    default_slot = (datetime.utcnow() + timedelta(hours=2)).strftime("%Y-%m-%dT%H:%M:%S")
    slot = top.get("available_slots", [default_slot])[0]
    book_result = run_booking_agent(
        provider=top,
        slot=slot,
        user_id=user_id,
        service_type=intent["service_type"],
        price_breakdown=bd,
    )
    all_trace.extend(book_result["trace"])

    # 5 — Followup
    if book_result["success"]:
        followup_result = run_followup_agent(
            booking_ref=book_result["booking"]["ref"],
            action="status_update",
            payload={"status": "reminder_scheduled"},
        )
        all_trace.extend(followup_result["trace"])

    # Compose human-readable response
    booking = book_result.get("booking")
    extra = intent.get("additional_services", [])
    if booking:
        response = (
            f"Booking confirmed! ✓\n\n"
            f"Provider: {top['name']} ({top['rating']}★)\n"
            f"Zone: {top['zone']} | Distance: {top.get('distance_km', '?')} km\n"
            f"Price: PKR {bd['total']} (2 hrs)\n"
            f"Slot: {slot}\n"
            f"Ref: {booking['ref']}\n\n"
            f"A reminder will be sent 1 hour before your appointment."
        )
        if extra:
            remaining = ", ".join(extra)
            response += f"\n\nAap ne {remaining} bhi request kiya tha — pehle {intent['service_type']} handle kar lete hain, phir {remaining} ke liye bhi book karein ge."
    else:
        alts = book_result.get("next_slots", [])
        response = (
            f"That slot is taken for {top['name']}. "
            f"Next available: {', '.join(alts[:2]) if alts else 'please check back later'}."
        )

    return {
        "success": True,
        "response": response,
        "intent": intent,
        "ranked_providers": [
            {"id": p["id"], "name": p["name"], "score": p.get("score"), "rating": p["rating"]}
            for p in ranked[:3]
        ],
        "booking": booking,
        "agent_trace": all_trace,
        "tools_called": ["parse_intent", "rank_providers", "calculate_price", "create_booking", "schedule_followup"],
        "orchestration": "direct_pipeline",
    }


# ═══════════════════════════════════════════════════════════════
# DIRECT ENDPOINTS — For granular testing & Flutter step-by-step
# These call agents directly (without ADK orchestration)
# ═══════════════════════════════════════════════════════════════

class IntentRequest(BaseModel):
    text: str
    user_id: str = "demo_user"
    session_id: Optional[str] = None

class RankRequest(BaseModel):
    service_type: str
    user_lat: float
    user_lng: float
    specialization: Optional[str] = None
    requested_slot: Optional[str] = None

class PriceRequest(BaseModel):
    provider_id: str
    hours: float = 2.0
    is_urgent: bool = False
    distance_km: float = 3.0
    peak_hour: bool = False

class BookRequest(BaseModel):
    provider_id: str
    slot: str
    user_id: str = "demo_user"
    service_type: str
    price_breakdown: dict
    session_id: Optional[str] = None

class FollowupRequest(BaseModel):
    booking_ref: str
    action: str
    payload: dict = {}

class ScenarioRequest(BaseModel):
    scenario: str
    user_lat: float = 24.8040
    user_lng: float = 67.0708


@app.post("/intent")
async def parse_intent(req: IntentRequest) -> dict[str, Any]:
    """IntentAgent: converts Urdu/English text → structured intent.
    When session_id is provided, merges with stored multi-turn context."""
    key = req.session_id or _default_trace_key
    _direct_traces[key] = []
    result = run_intent_agent(req.text)
    intent = result["intent"]
    trace  = result["trace"]

    # ── Multi-turn context merge ─────────────────────────────────
    stored      = _get_ctx(req.session_id)
    memory_used = {}

    if req.session_id and stored:
        # Fill missing service from prior turn
        if not intent["service_type"] and stored.get("service_type"):
            intent["service_type"] = stored["service_type"]
            intent["ambiguous"]    = False
            intent["clarification_question"] = None
            memory_used["service_type"] = stored["service_type"]

        # Fill missing zone only when user didn't explicitly state one
        if not intent.get("zone_explicit") and stored.get("zone"):
            intent["zone"] = stored["zone"]
            memory_used["zone"] = stored["zone"]

        # Carry forward urgency (once urgent, stays urgent for session)
        if not intent["is_urgent"] and stored.get("is_urgent"):
            intent["is_urgent"] = True
            memory_used["is_urgent"] = True

    # Inject ContextAgent trace step when memory was used (visible in trace panel)
    if memory_used:
        recalled = ", ".join(f"{k}='{v}'" for k, v in memory_used.items())
        trace.insert(0, {
            "agent":     "ContextAgent",
            "step":      "memory_recall",
            "input":     {"session_id": req.session_id, "current_text": req.text},
            "output":    memory_used,
            "reasoning": f"Recalled from prior turns: {recalled}. "
                         f"Merging with current message so user doesn't need to repeat themselves.",
            "timestamp": datetime.utcnow().isoformat(),
        })

    # Persist updated context for next turn
    _save_ctx(req.session_id, {
        "service_type": intent["service_type"],
        "zone":         intent["zone"] if intent.get("zone_explicit") else stored.get("zone"),
        "is_urgent":    intent["is_urgent"],
    })

    _record_trace(trace, req.session_id)
    return {
        "intent":      intent,
        "agent_trace": trace,
        "memory_used": memory_used,
    }


@app.post("/rank")
async def rank_providers(req: RankRequest) -> dict[str, Any]:
    """RankAgent: weighted scoring of providers."""
    result = run_rank_agent(
        providers=_providers,
        user_lat=req.user_lat,
        user_lng=req.user_lng,
        service_type=req.service_type,
        specialization=req.specialization,
        requested_slot=req.requested_slot,
    )
    _record_trace(result["trace"])
    return {"ranked": result["ranked"][:5], "agent_trace": result["trace"]}


@app.post("/price")
async def calculate_price(req: PriceRequest) -> dict[str, Any]:
    """PriceAgent: dynamic PKR quote."""
    provider = next((p for p in _providers if p["id"] == req.provider_id), None)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")
    result = run_price_agent(
        provider=provider, hours=req.hours, is_urgent=req.is_urgent,
        distance_km=req.distance_km, peak_hour=req.peak_hour,
    )
    _record_trace(result["trace"])
    return {"provider_id": req.provider_id, "breakdown": result["breakdown"], "agent_trace": result["trace"]}


@app.post("/book")
async def create_booking(req: BookRequest) -> dict[str, Any]:
    """BookingAgent: confirm slot + write booking."""
    provider = next((p for p in _providers if p["id"] == req.provider_id), None)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")
    result = run_booking_agent(
        provider=provider, slot=req.slot, user_id=req.user_id,
        service_type=req.service_type, price_breakdown=req.price_breakdown,
    )
    _record_trace(result["trace"])
    # Save booking ref to session so FollowupAgent can always find it
    if result.get("success") and result.get("booking") and req.session_id:
        _save_ctx(req.session_id, {"last_booking_ref": result["booking"]["ref"]})
    return {
        "success": result["success"], "booking": result.get("booking"),
        "error": result.get("error"), "message": result.get("message"),
        "next_slots": result.get("next_slots"), "agent_trace": result["trace"],
    }


@app.post("/followup")
async def handle_followup(req: FollowupRequest) -> dict[str, Any]:
    """FollowupAgent: post-booking events."""
    result = run_followup_agent(
        booking_ref=req.booking_ref, action=req.action, payload=req.payload,
    )
    _record_trace(result["trace"])
    return {**result, "agent_trace": result["trace"]}


# ═══════════════════════════════════════════════════════════════
# TRACE & DEMO ENDPOINTS
# ═══════════════════════════════════════════════════════════════

@app.get("/trace")
async def get_trace(session_id: str = None) -> dict[str, Any]:
    """Returns full agent trace (ADK orchestrator + individual agents)."""
    adk_trace = get_session_trace(session_id)
    direct_trace = _direct_traces.get(session_id or _default_trace_key, [])
    combined = adk_trace + direct_trace
    return {
        "session_trace": combined,
        "step_count": len(combined),
        "agents_involved": list({s["agent"] for s in combined}),
    }


@app.post("/scenario")
async def run_scenario(req: ScenarioRequest) -> dict[str, Any]:
    """Demo stress-test scenarios — routed through ADK orchestrator."""
    from datetime import timedelta
    tomorrow_9am = (datetime.utcnow() + timedelta(days=1)).strftime("%Y-%m-%d") + "T09:00:00"
    scenario_prompts = {
        "A": f"Mujhe DHA Phase 2 mein AC repair chahiye abhi. Slot {tomorrow_9am} book karo.",
        "B": "G-13 Islamabad mein AC technician chahiye kal subah 10 baje",
        "C": "koi repair wala chahiye ghar mein",
        "D": "Electrician chahiye DHA mein, urgent hai",
    }

    prompt = scenario_prompts.get(req.scenario)
    if not prompt:
        raise HTTPException(status_code=400, detail="Unknown scenario. Use A, B, C, or D.")

    # For scenario A, inject a conflicting booking first
    if req.scenario == "A":
        conflict_provider = next(p for p in _providers if p["service_type"] == "ac_repair" and p["is_available"])
        _bookings_db.append({
            "ref": "HMZ-SCENARIO-A",
            "provider_id": conflict_provider["id"],
            "slot": tomorrow_9am,
            "status": "confirmed",
        })

    try:
        result = await run_orchestrator(user_text=prompt, user_id="demo_judge")
        return {
            "scenario": req.scenario,
            "prompt": prompt,
            "description": {
                "A": "Double-booked slot → system detects conflict and suggests alternative",
                "B": "No provider in zone → fallback to nearest zone + waitlist",
                "C": "Ambiguous input → agent asks for clarification",
                "D": "Full end-to-end booking with automated follow-up",
            }[req.scenario],
            "response": result["response"],
            "tools_called": result["tools_called"],
            "agent_trace": result["agent_trace"],
        }
    except Exception as e:
        return {"scenario": req.scenario, "error": str(e), "agent_trace": []}


@app.get("/health")
async def health() -> dict:
    return {
        "status": "ok",
        "orchestrator": "Google ADK (Antigravity)",
        "model": "gemini-2.5-flash (Google ADK orchestrated)",
        "providers": len(_providers),
        "bookings": len(_bookings_db),
        "active_sessions": len(_session_contexts),
    }


# ═══════════════════════════════════════════════════════════════
# SESSION MEMORY ENDPOINTS
# ═══════════════════════════════════════════════════════════════

@app.get("/session/{session_id}")
async def get_session(session_id: str) -> dict:
    """Return accumulated context for a session."""
    return _session_contexts.get(session_id, {})


@app.delete("/session/{session_id}")
async def clear_session(session_id: str) -> dict:
    """Clear stored context for a session (New Chat)."""
    _session_contexts.pop(session_id, None)
    return {"cleared": True, "session_id": session_id}


# ═══════════════════════════════════════════════════════════════
# STRIPE PAYMENT ENDPOINTS (Sandbox / Test mode)
# PKR is a 2-decimal currency in Stripe — amount must be in paisas (× 100)
# ═══════════════════════════════════════════════════════════════

class PaymentIntentRequest(BaseModel):
    booking_id: str
    amount_pkr: int          # e.g. 1710 for PKR 1,710 (we multiply × 100 for Stripe paisas)
    currency: str = "pkr"
    provider_name: str = ""
    service_type: str = ""


@app.post("/create-payment-intent")
async def create_payment_intent(req: PaymentIntentRequest) -> dict:
    """
    Creates a Stripe PaymentIntent for a confirmed booking.
    Returns a clientSecret the frontend uses to render Payment Elements.
    PKR is 2-decimal in Stripe: multiply by 100 to get paisas.
    """
    if req.amount_pkr < 50:
        raise HTTPException(status_code=400, detail="Minimum charge is PKR 50.")
    amount_cents = req.amount_pkr * 100    # smallest currency unit (cents/paisas)
    try:
        intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency=req.currency,
            payment_method_types=["card"],
            metadata={
                "booking_id":    req.booking_id,
                "provider_name": req.provider_name,
                "service_type":  req.service_type,
                "platform":      "HizmatAI",
                "mode":          "sandbox",
            },
            description=f"HizmatAI — {req.service_type} by {req.provider_name} (Booking {req.booking_id})",
        )
        return {
            "clientSecret":      intent.client_secret,
            "payment_intent_id": intent.id,
            "amount":            req.amount_pkr,
            "currency":          req.currency.upper(),
        }
    except stripe.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/payment-status/{payment_intent_id}")
async def get_payment_status(payment_intent_id: str) -> dict:
    """Retrieve the current status of a PaymentIntent."""
    try:
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)
        return {
            "status":     intent.status,
            "amount":     intent.amount,
            "currency":   intent.currency.upper(),
            "booking_id": intent.metadata.get("booking_id"),
        }
    except stripe.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))
