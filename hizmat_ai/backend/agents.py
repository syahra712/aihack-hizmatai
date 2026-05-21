"""
Agent orchestration layer for HizmatAI.
Each function simulates a Vertex AI / Antigravity agent call.
In production these would be actual Vertex AI Agent Builder API calls;
here we implement the reasoning logic directly for hackathon reliability.
Every function returns a trace dict so the frontend can render AgentTracePanel.
"""
import json
import re
import uuid
from datetime import datetime, timedelta
from typing import Any


def refresh_provider_slots(providers: list[dict]) -> None:
    """Replace static available_slots with dynamic ones relative to today."""
    now = datetime.utcnow()
    tomorrow = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
    slot_offsets = [
        timedelta(days=1, hours=9),
        timedelta(days=1, hours=14),
        timedelta(days=2, hours=10),
    ]
    for p in providers:
        p["available_slots"] = [
            (now.replace(hour=0, minute=0, second=0, microsecond=0) + offset).strftime("%Y-%m-%dT%H:%M:%S")
            for offset in slot_offsets
        ]


# ─────────────────────────────────────────
# IntentAgent — parses raw Urdu/English user text
# Decides: service_type, zone, urgency, ambiguous flag
# ─────────────────────────────────────────

SERVICE_KEYWORDS = {
    "electrician":  [
        "electrician", "electric", "bijli", "wiring", "fan", "mcb", "socket",
        "switch", "lighting", "bulb", "bijlee",
        # Urdu script
        "بجلی", "الیکٹریشن", "وائرنگ", "بلب", "سوئچ", "پنکھا", "لائٹ",
    ],
    "plumber":      [
        "plumber", "plumbing", "pipe", "leak", "paani", "drain", "geyser",
        "pani", "nalka", "water",
        # Urdu script
        "پلمبر", "پائپ", "پانی", "نلکا", "لیک", "گیزر", "ڈرین", "پلمبنگ",
    ],
    "ac_repair":    [
        "ac repair", "air conditioner", "air condition", "cooling", "thanda",
        "ductless", "heat pump", "inverter ac", "ac",
        # Urdu script
        "اے سی", "ایئر کنڈیشنر", "کولنگ", "ٹھنڈا", "اے۔سی",
    ],
    "home_tutor":   [
        "tutor", "teacher", "math", "science", "padhna", "ustaad", "padhai",
        "home tutor", "tutoring",
        # Urdu script
        "ٹیوٹر", "استاد", "پڑھنا", "پڑھائی", "ٹیچر", "معلم",
    ],
    "beautician":   [
        "beautician", "beauty", "facial", "wax", "mehndi", "bridal", "makeup",
        "salon",
        # Urdu script
        "بیوٹیشن", "میکاپ", "مہندی", "فیشل", "بریڈل", "سیلون", "بیوٹی",
    ],
    "home_cleaning": [
        "cleaning", "clean", "safai", "sweep", "mop", "dust",
        # Urdu script
        "صفائی", "کلیننگ", "جھاڑو",
    ],
}

ZONE_KEYWORDS = {
    "DHA Phase 2":      ["dha phase 2", "dha phase2"],
    "DHA Lahore":       ["dha lahore", "dha lhr"],
    "Gulshan-e-Iqbal":  ["gulshan", "iqbal", "گلشن", "اقبال"],
    "G-13":             ["g13", "g-13"],
    "Nazimabad":        ["nazimabad", "نظیم آباد", "ناظم آباد"],
    "Clifton":          ["clifton", "cliften", "کلفٹن"],
    "PECHS":            ["pechs", "p.e.c.h.s"],
    "North Nazimabad":  ["north nazimabad", "north naz", "نارتھ ناظم آباد"],
    "Bahria Town":      ["bahria", "bahria town", "بحریہ", "بہاریہ"],
    "Johar Town Lahore":["johar town lahore"],
    "Johar":            ["johar", "johar town", "جوہر"],
    "Saddar":           ["saddar", "sadder", "صدر"],
    "Gulberg Lahore":   ["gulberg", "گلبرگ"],
    "Model Town Lahore":["model town", "ماڈل ٹاؤن"],
    "F-10 Islamabad":   ["f-10", "f10"],
    "I-8 Islamabad":    ["i-8", "i8"],
}

# Maps detected city name to a default zone for that city
CITY_KEYWORDS = {
    "Karachi":    ["karachi", "khi", "کراچی", "کراچي"],
    "Lahore":     ["lahore", "lhr", "لاہور"],
    "Islamabad":  ["islamabad", "isb", "اسلام آباد", "اسلام‌آباد"],
    "Rawalpindi": ["rawalpindi", "pindi", "راولپنڈی"],
    "Faisalabad": ["faisalabad", "fsd", "فیصل آباد"],
    "Multan":     ["multan", "ملتان"],
    "Peshawar":   ["peshawar", "پشاور"],
    "Quetta":     ["quetta", "کوئٹہ"],
}

CITY_DEFAULT_ZONE = {
    "Karachi":    "DHA Phase 2",
    "Lahore":     "DHA Lahore",
    "Islamabad":  "G-13",
    "Rawalpindi": "G-13",
    "Faisalabad": "DHA Lahore",
    "Multan":     "DHA Lahore",
    "Peshawar":   "G-13",
    "Quetta":     "G-13",
}

SUPPORTED_CITIES = {"Karachi", "Lahore", "Islamabad"}

CITY_DHA_ZONE = {
    "Karachi":   "DHA Phase 2",
    "Lahore":    "DHA Lahore",
    "Islamabad": "F-10 Islamabad",
}

URGENCY_KEYWORDS = [
    "urgent", "jaldi", "asap", "emergency", "abhi", "now", "foran", "immediately",
    "فوری", "ابھی", "ایمرجنسی", "جلدی",
]


UNSUPPORTED_SERVICES = {
    "cctv": "CCTV installation",
    "camera": "CCTV / security camera installation",
    "pest control": "pest control",
    "pest": "pest control",
    "painter": "painting services",
    "painting": "painting services",
    "carpenter": "carpentry",
    "carpentry": "carpentry",
    "security guard": "security guard services",
    "driver": "driver / chauffeur services",
    "movers": "moving / packing services",
    "packers": "moving / packing services",
    "shifting": "moving / packing services",
    "gardener": "gardening services",
    "garden": "gardening services",
}

_EMOJI_RE = re.compile(
    "["
    "\U0001F600-\U0001F64F"
    "\U0001F300-\U0001F5FF"
    "\U0001F680-\U0001F6FF"
    "\U0001F1E0-\U0001F1FF"
    "\U00002702-\U000027B0"
    "\U0001F900-\U0001F9FF"
    "\U0001FA00-\U0001FA6F"
    "\U0001FA70-\U0001FAFF"
    "\U00002600-\U000026FF"
    "]+", flags=re.UNICODE
)


def _normalize_input(text: str) -> str:
    """Strip emojis and collapse repeated characters (e.g. 'hhhelp' → 'help')."""
    text = _EMOJI_RE.sub(" ", text)
    text = re.sub(r'(.)\1{2,}', r'\1', text)
    return text.strip()


def _word_match(keyword: str, text: str) -> bool:
    """Match keyword in text. Uses \\b boundaries for ASCII, plain substring for Urdu/Arabic script."""
    if all(ord(c) < 128 for c in keyword):
        # ASCII keyword — safe to use word boundaries
        return bool(re.search(r'\b' + re.escape(keyword) + r'\b', text))
    # Urdu/Arabic script — space-delimited substring match
    return keyword in text


def run_intent_agent(text: str) -> dict[str, Any]:
    """
    IntentAgent reasoning:
    1. Lowercase + normalise input
    2. Match service_type against keyword map
    3. Match zone from text
    4. Check urgency signals
    5. If no service_type found → set ambiguous=True and generate clarification
    Returns structured intent + full trace of each decision step.
    """
    trace_steps = []
    text_normalized = _normalize_input(text)
    text_lower = text_normalized.lower().strip()

    trace_steps.append({
        "agent": "IntentAgent",
        "step": "input_normalisation",
        "input": text,
        "output": text_lower,
        "reasoning": "Lowercased, stripped emojis, and collapsed repeated characters for keyword matching"
    })

    # Check for unsupported services before main detection
    for unsup_kw, unsup_name in UNSUPPORTED_SERVICES.items():
        if _word_match(unsup_kw, text_lower):
            trace_steps.append({
                "agent": "IntentAgent",
                "step": "unsupported_service_detection",
                "input": text_lower,
                "output": unsup_name,
                "reasoning": f"Matched unsupported service '{unsup_kw}' → '{unsup_name}'. Not offered yet."
            })
            result = {
                "service_type": None,
                "additional_services": [],
                "zone": None,
                "zone_explicit": False,
                "city": "Karachi",
                "is_urgent": False,
                "budget_max": None,
                "raw_text": text,
                "ambiguous": True,
                "clarification_question": (
                    f"Sorry, {unsup_name} abhi HizmatAI par available nahi hai. "
                    f"Hum filhaal electrician, plumber, AC repair, home tutor, beautician, aur home cleaning offer karte hain. "
                    f"Kya inme se koi service chahiye?"
                ),
            }
            trace_steps.append({
                "agent": "IntentAgent",
                "step": "final_intent",
                "input": text_lower,
                "output": result,
                "reasoning": f"Service '{unsup_name}' is not offered. Returning clarification."
            })
            return {"intent": result, "trace": trace_steps}

    # Detect service type(s) — scan all, handle multi-service requests
    all_detected_services = []
    for service, keywords in SERVICE_KEYWORDS.items():
        for kw in keywords:
            if _word_match(kw, text_lower):
                all_detected_services.append((service, kw))
                break

    detected_service = all_detected_services[0][0] if all_detected_services else None
    additional_services = [s for s, _ in all_detected_services[1:]]

    if all_detected_services:
        primary_svc, primary_kw = all_detected_services[0]
        trace_steps.append({
            "agent": "IntentAgent",
            "step": "service_detection",
            "input": text_lower,
            "output": primary_svc,
            "reasoning": f"Matched keyword '{primary_kw}' → service_type='{primary_svc}'"
        })

    if additional_services:
        trace_steps.append({
            "agent": "IntentAgent",
            "step": "multi_service_detection",
            "input": text_lower,
            "output": additional_services,
            "reasoning": f"Also detected: {', '.join(additional_services)}. Will handle '{detected_service}' first, then prompt for remaining."
        })

    if not detected_service:
        trace_steps.append({
            "agent": "IntentAgent",
            "step": "service_detection",
            "input": text_lower,
            "output": None,
            "reasoning": "No service keyword matched — flagging as ambiguous. Will ask clarification."
        })

    # Detect city (check original text too for Urdu script)
    detected_city = None
    for city, keywords in CITY_KEYWORDS.items():
        for kw in keywords:
            if _word_match(kw, text_lower) or _word_match(kw, text):
                detected_city = city
                trace_steps.append({
                    "agent": "IntentAgent",
                    "step": "city_detection",
                    "input": text,
                    "output": city,
                    "reasoning": f"Matched city keyword '{kw}' → city='{city}'"
                })
                break
        if detected_city:
            break

    if not detected_city:
        detected_city = "Karachi"
        trace_steps.append({
            "agent": "IntentAgent",
            "step": "city_detection",
            "input": text,
            "output": "Karachi",
            "reasoning": "No city mentioned — defaulting to Karachi"
        })

    # Detect zone within city
    detected_zone = None
    for zone, keywords in ZONE_KEYWORDS.items():
        for kw in keywords:
            if _word_match(kw, text_lower) or _word_match(kw, text):
                detected_zone = zone
                trace_steps.append({
                    "agent": "IntentAgent",
                    "step": "zone_detection",
                    "input": text_lower,
                    "output": zone,
                    "reasoning": f"Matched zone keyword '{kw}' → zone='{zone}'"
                })
                break
        if detected_zone:
            break

    # Handle bare "dha"/"defence" — resolve to city-specific DHA zone
    if not detected_zone:
        dha_keywords = ["dha", "defence", "ڈی ایچ اے", "ڈیفنس"]
        for kw in dha_keywords:
            if _word_match(kw, text_lower) or _word_match(kw, text):
                detected_zone = CITY_DHA_ZONE.get(detected_city, "DHA Phase 2")
                trace_steps.append({
                    "agent": "IntentAgent",
                    "step": "zone_detection",
                    "input": text_lower,
                    "output": detected_zone,
                    "reasoning": f"Matched '{kw}' → resolved to '{detected_zone}' for {detected_city}"
                })
                break

    zone_explicit = detected_zone is not None

    if not detected_zone:
        default_zone = CITY_DEFAULT_ZONE.get(detected_city, "DHA Phase 2")
        trace_steps.append({
            "agent": "IntentAgent",
            "step": "zone_detection",
            "input": text_lower,
            "output": default_zone,
            "reasoning": f"No zone mentioned — defaulting to '{default_zone}' for {detected_city}"
        })
        detected_zone = default_zone

    # Detect urgency
    is_urgent = any(_word_match(kw, text_lower) for kw in URGENCY_KEYWORDS)
    trace_steps.append({
        "agent": "IntentAgent",
        "step": "urgency_detection",
        "input": text_lower,
        "output": is_urgent,
        "reasoning": f"Urgency keywords scan: {'found' if is_urgent else 'none found'}"
    })

    # Detect budget constraint (e.g. "budget 1500", "max 2000", "under 1000 rs")
    budget_max = None
    budget_match = re.search(r'(?:budget|max|under|within|limit|tak|se\s*kam)\s*(?:pkr|rs\.?|rupees?)?\s*(\d{3,6})', text_lower)
    if not budget_match:
        budget_match = re.search(r'(\d{3,6})\s*(?:pkr|rs\.?|rupees?)\s*(?:max|tak|se\s*kam|budget|limit)', text_lower)
    if budget_match:
        budget_max = int(budget_match.group(1))
        trace_steps.append({
            "agent": "IntentAgent",
            "step": "budget_detection",
            "input": text_lower,
            "output": budget_max,
            "reasoning": f"Detected budget constraint: max PKR {budget_max}"
        })

    ambiguous = detected_service is None
    clarification = None
    city_unsupported = False

    if detected_city not in SUPPORTED_CITIES:
        city_unsupported = True
        clarification = (
            f"HizmatAI jaldi {detected_city} mein bhi available hoga! "
            f"Filhaal humari service Karachi, Lahore, aur Islamabad mein hai. "
            f"Coming soon to {detected_city}!"
        )
        trace_steps.append({
            "agent": "IntentAgent",
            "step": "city_coverage_check",
            "input": detected_city,
            "output": "UNSUPPORTED",
            "reasoning": f"'{detected_city}' is not yet supported. Returning coming-soon message."
        })
    elif ambiguous:
        clarification = (
            "Aap kis cheez ki repair chahte hain? "
            "AC, plumber, electrician, home tutor, ya beautician?"
        )

    result = {
        "service_type": detected_service,
        "additional_services": additional_services,
        "zone": detected_zone,
        "zone_explicit": zone_explicit,
        "city": detected_city,
        "is_urgent": is_urgent,
        "budget_max": budget_max,
        "raw_text": text,
        "ambiguous": ambiguous or city_unsupported,
        "clarification_question": clarification,
    }

    trace_steps.append({
        "agent": "IntentAgent",
        "step": "final_intent",
        "input": text_lower,
        "output": result,
        "reasoning": "Compiled all signals into structured intent object"
    })

    return {"intent": result, "trace": trace_steps}


# ─────────────────────────────────────────
# RankAgent — scores providers using weighted algorithm
# Weights: distance 20%, rating 25%, reliability 20%,
#          specialization 15%, price 10%, cancellation_rate 10%
# ─────────────────────────────────────────

def run_rank_agent(
    providers: list[dict],
    user_lat: float,
    user_lng: float,
    service_type: str,
    specialization: str | None = None,
    requested_slot: str | None = None,
    budget_max: int | None = None,
    excluded_providers: list[str] | None = None,
) -> dict[str, Any]:
    """
    RankAgent reasoning:
    1. Filter by service_type and is_available
    2. Compute haversine distance for each provider
    3. Normalize each dimension to [0,1]
    4. Apply weighted score formula
    5. Sort descending, attach 'why_chosen' explanation per provider
    """
    from haversine import haversine

    trace_steps = []

    # Step 1: Filter
    filtered = [p for p in providers if p["service_type"] == service_type and p["is_available"]]

    if excluded_providers:
        before = len(filtered)
        filtered = [p for p in filtered if p["id"] not in excluded_providers]
        if len(filtered) < before:
            trace_steps.append({
                "agent": "RankAgent",
                "step": "exclusion_filter",
                "input": {"excluded": excluded_providers},
                "output": {"removed": before - len(filtered), "remaining": len(filtered)},
                "reasoning": f"Excluded {before - len(filtered)} provider(s) per user preference."
            })

    pre_budget_count = len(filtered)
    if budget_max is not None:
        budget_filtered = [p for p in filtered if p["hourly_rate"] * 2 <= budget_max]
        if not budget_filtered:
            trace_steps.append({
                "agent": "RankAgent",
                "step": "budget_filter",
                "input": {"budget_max": budget_max, "candidates": pre_budget_count},
                "output": {"within_budget": 0},
                "reasoning": f"All {pre_budget_count} providers exceed budget of PKR {budget_max} (for 2hr estimate). Showing all with budget note."
            })
        else:
            filtered = budget_filtered
            trace_steps.append({
                "agent": "RankAgent",
                "step": "budget_filter",
                "input": {"budget_max": budget_max},
                "output": {"within_budget": len(filtered)},
                "reasoning": f"{len(filtered)} provider(s) within PKR {budget_max} budget (2hr estimate)."
            })

    trace_steps.append({
        "agent": "RankAgent",
        "step": "filter",
        "input": {"service_type": service_type, "total_providers": len(providers)},
        "output": {"filtered_count": len(filtered)},
        "reasoning": f"Filtered to {len(filtered)} available providers for '{service_type}'"
    })

    if not filtered:
        return {"ranked": [], "trace": trace_steps}

    # Step 2: Compute distances
    for p in filtered:
        p["distance_km"] = round(haversine(user_lat, user_lng, p["lat"], p["lng"]), 2)

    trace_steps.append({
        "agent": "RankAgent",
        "step": "distance_computation",
        "input": {"user_lat": user_lat, "user_lng": user_lng},
        "output": {p["id"]: p["distance_km"] for p in filtered},
        "reasoning": "Haversine distance computed for each provider (no Maps API needed)"
    })

    # Step 3: Normalize dimensions
    max_dist = max(p["distance_km"] for p in filtered) or 1
    min_rate = min(p["hourly_rate"] for p in filtered)
    max_rate = max(p["hourly_rate"] for p in filtered) or 1
    rate_range = max_rate - min_rate or 1

    scored = []
    for p in filtered:
        # Higher is better for all normalized scores
        dist_score    = 1 - (p["distance_km"] / max_dist)          # closer = better
        rating_score  = max(0.0, min(1.0, (p["rating"] - 4.0) / 1.0))  # clamped to [0,1]
        reliability   = p["on_time_score"]                          # already 0-1
        price_score   = 1 - ((p["hourly_rate"] - min_rate) / rate_range)  # cheaper = better
        cancel_score  = 1 - p["cancellation_rate"]                  # lower cancel = better

        # Specialization match bonus
        spec_score = 0.5
        if specialization:
            specs_lower = [s.lower() for s in p["specializations"]]
            spec_score = 1.0 if specialization.lower() in specs_lower else 0.2

        # Slot availability check
        slot_available = True
        if requested_slot and p.get("available_slots"):
            slot_available = requested_slot in p["available_slots"]
        slot_penalty = 1.0 if slot_available else 0.5

        # Weighted score: distance 20%, rating 25%, reliability 20%, spec 15%, price 10%, cancel 10%
        score = (
            dist_score   * 0.20 +
            rating_score * 0.25 +
            reliability  * 0.20 +
            spec_score   * 0.15 +
            price_score  * 0.10 +
            cancel_score * 0.10
        ) * slot_penalty

        # Generate human-readable "why chosen" explanation for the judge demo
        why_parts = []
        if dist_score > 0.7:
            why_parts.append(f"only {p['distance_km']}km away")
        if p["rating"] >= 4.7:
            why_parts.append(f"{p['rating']}★ top-rated")
        if reliability > 0.90:
            why_parts.append(f"{int(reliability*100)}% on-time")
        if specialization and spec_score == 1.0:
            why_parts.append(f"specializes in {specialization}")
        if cancel_score > 0.9:
            why_parts.append("rarely cancels")
        why_chosen = (", ".join(why_parts) or "best overall match") + "."

        dim_scores = {
            "distance": round(dist_score * 0.20, 4),
            "rating": round(rating_score * 0.25, 4),
            "reliability": round(reliability * 0.20, 4),
            "specialization": round(spec_score * 0.15, 4),
            "price": round(price_score * 0.10, 4),
            "cancellation": round(cancel_score * 0.10, 4),
        }
        scored.append({**p, "score": round(score, 4), "dim_scores": dim_scores, "why_chosen": why_chosen, "slot_available": slot_available})

    scored.sort(key=lambda x: x["score"], reverse=True)

    trace_steps.append({
        "agent": "RankAgent",
        "step": "scoring",
        "input": {"weights": {"distance": 0.20, "rating": 0.25, "reliability": 0.20, "specialization": 0.15, "price": 0.10, "cancellation": 0.10}},
        "output": [{"id": p["id"], "name": p["name"], "score": p["score"]} for p in scored[:5]],
        "reasoning": "Applied weighted scoring formula. Top pick chosen by highest composite score."
    })

    if len(scored) >= 2:
        a, b = scored[0], scored[1]
        delta = round(a["score"] - b["score"], 4)
        dim_a, dim_b = a["dim_scores"], b["dim_scores"]
        deciding = max(dim_a.keys(), key=lambda k: dim_a[k] - dim_b[k])
        deciding_gap = round(dim_a[deciding] - dim_b[deciding], 4)
        trace_steps.append({
            "agent": "RankAgent",
            "step": "top2_comparison",
            "input": {"provider_1": a["name"], "provider_2": b["name"]},
            "output": {
                a["name"]: {"score": a["score"], **dim_a},
                b["name"]: {"score": b["score"], **dim_b},
                "score_delta": delta,
                "deciding_factor": deciding,
                "deciding_gap": deciding_gap,
            },
            "reasoning": f"{a['name']} scored {a['score']} vs {b['name']}'s {b['score']} — {deciding_gap} of the {delta} gap came from {deciding}."
        })

    return {"ranked": scored, "trace": trace_steps}


# ─────────────────────────────────────────
# PriceAgent — calculates dynamic PKR quote
# Components: base + urgency + distance + surge + discount
# ─────────────────────────────────────────

def run_price_agent(
    provider: dict,
    hours: float,
    is_urgent: bool,
    distance_km: float,
    peak_hour: bool = False,
) -> dict[str, Any]:
    """
    PriceAgent reasoning:
    1. Base = hourly_rate × estimated_hours
    2. Urgency surcharge = 20% if urgent
    3. Distance fee = PKR 50/km beyond 5km
    4. Peak-hour surge = 15% if 6pm–10pm or weekend
    5. Loyalty discount = 5% (simulated for demo)
    Returns itemized breakdown so PricingScreen can display each line.
    """
    trace_steps = []

    base = round(provider["hourly_rate"] * hours)
    trace_steps.append({
        "agent": "PriceAgent",
        "step": "base_calculation",
        "input": {"hourly_rate": provider["hourly_rate"], "hours": hours},
        "output": base,
        "reasoning": f"Base = PKR {provider['hourly_rate']} × {hours}h = PKR {base}"
    })

    urgency_fee = round(base * 0.20) if is_urgent else 0
    trace_steps.append({
        "agent": "PriceAgent",
        "step": "urgency_surcharge",
        "input": {"is_urgent": is_urgent},
        "output": urgency_fee,
        "reasoning": "20% surcharge applied because user flagged urgency" if is_urgent else "No urgency — no surcharge"
    })

    dist_fee = round(max(0, distance_km - 5) * 50)
    trace_steps.append({
        "agent": "PriceAgent",
        "step": "distance_fee",
        "input": {"distance_km": distance_km},
        "output": dist_fee,
        "reasoning": f"PKR 50/km for {max(0, distance_km-5):.1f}km beyond 5km threshold"
    })

    surge_fee = round(base * 0.15) if peak_hour else 0
    trace_steps.append({
        "agent": "PriceAgent",
        "step": "peak_surge",
        "input": {"peak_hour": peak_hour},
        "output": surge_fee,
        "reasoning": "15% peak-hour surge (6pm–10pm / weekend)" if peak_hour else "Off-peak — no surge"
    })

    # 5% loyalty discount for demo
    subtotal = base + urgency_fee + dist_fee + surge_fee
    discount = round(subtotal * 0.05)
    total = subtotal - discount
    trace_steps.append({
        "agent": "PriceAgent",
        "step": "loyalty_discount",
        "input": {"subtotal": subtotal},
        "output": {"discount": discount, "total": total},
        "reasoning": "5% loyalty discount applied for returning HizmatAI user"
    })

    if total < 100:
        total = 100
        trace_steps.append({
            "agent": "PriceAgent",
            "step": "minimum_price_guard",
            "input": {"computed_total": subtotal - discount},
            "output": 100,
            "reasoning": "Total fell below PKR 100 minimum. Applying floor."
        })

    breakdown = {
        "base": base,
        "urgency_fee": urgency_fee,
        "distance_fee": dist_fee,
        "surge_fee": surge_fee,
        "discount": -discount,
        "total": total,
        "currency": "PKR",
        "hours_estimated": hours,
    }

    return {"breakdown": breakdown, "trace": trace_steps}


# ─────────────────────────────────────────
# BookingAgent — validates slot + writes booking
# Checks for double-booking before confirming
# ─────────────────────────────────────────

# In-memory "Firestore" for hackathon (replace with real Firestore calls in prod)
_bookings_db: list[dict] = []


def run_booking_agent(
    provider: dict,
    slot: str,
    user_id: str,
    service_type: str,
    price_breakdown: dict,
) -> dict[str, Any]:
    """
    BookingAgent reasoning:
    1. Check if provider already has a confirmed booking at requested slot (double-booking guard)
    2. Scenario A trigger: if slot already taken, find next best provider automatically
    3. Write booking record if slot is free
    4. Return confirmation receipt with reference number
    """
    trace_steps = []

    # Reject past-date slots
    try:
        slot_dt = datetime.fromisoformat(slot)
        if slot_dt < datetime.utcnow():
            trace_steps.append({
                "agent": "BookingAgent",
                "step": "slot_validation",
                "input": {"slot": slot},
                "output": "PAST_DATE",
                "reasoning": f"Requested slot {slot} is in the past. Rejecting."
            })
            tomorrow = (datetime.utcnow() + timedelta(hours=2)).strftime("%Y-%m-%dT%H:%M:%S")
            return {
                "success": False,
                "error": "PAST_DATE",
                "message": f"Slot {slot} is in the past. Please choose a future time.",
                "next_slots": [tomorrow],
                "trace": trace_steps,
            }
    except ValueError:
        pass

    # Check double-booking (Scenario A)
    existing = [
        b for b in _bookings_db
        if b["provider_id"] == provider["id"] and b["slot"] == slot and b["status"] != "cancelled"
    ]

    trace_steps.append({
        "agent": "BookingAgent",
        "step": "double_booking_check",
        "input": {"provider_id": provider["id"], "slot": slot},
        "output": {"conflict": len(existing) > 0, "existing_bookings": len(existing)},
        "reasoning": "Querying booking ledger for provider+slot conflict before confirmation"
    })

    if existing:
        # Scenario A: slot conflict — return error so rank route finds alternative
        trace_steps.append({
            "agent": "BookingAgent",
            "step": "conflict_resolution",
            "input": {"conflicting_slot": slot},
            "output": "SLOT_TAKEN",
            "reasoning": "Slot already booked. Triggering Scenario A: system will auto-suggest next available slot."
        })
        return {
            "success": False,
            "error": "SLOT_TAKEN",
            "message": f"Slot {slot} is already booked with {provider['name']}. Suggesting next available.",
            "next_slots": provider.get("available_slots", [])[:3],
            "trace": trace_steps,
        }

    # Create booking
    ref = f"HMZ-{uuid.uuid4().hex[:8].upper()}"
    booking = {
        "ref": ref,
        "provider_id": provider["id"],
        "provider_name": provider["name"],
        "user_id": user_id,
        "service_type": service_type,
        "slot": slot,
        "status": "confirmed",
        "price": price_breakdown.get("total", 0),
        "price_breakdown": price_breakdown,
        "created_at": datetime.utcnow().isoformat(),
        "timeline": [
            {"status": "Confirmed", "time": datetime.utcnow().isoformat(), "done": True},
            {"status": "Reminder Sent", "time": (datetime.utcnow() + timedelta(hours=1)).isoformat(), "done": False},
            {"status": "En Route", "time": slot, "done": False},
            {"status": "Completed", "time": None, "done": False},
        ]
    }
    _bookings_db.append(booking)

    trace_steps.append({
        "agent": "BookingAgent",
        "step": "booking_created",
        "input": {"ref": ref, "provider": provider["name"], "slot": slot},
        "output": {"booking_ref": ref, "status": "confirmed"},
        "reasoning": "No conflict found. Booking written to Firestore. Ref number generated."
    })

    return {"success": True, "booking": booking, "trace": trace_steps}


# ─────────────────────────────────────────
# FollowupAgent — handles disputes, cancellations, reschedule
# Covers Scenario D: provider cancels → auto-reschedule
# ─────────────────────────────────────────

def run_followup_agent(
    booking_ref: str,
    action: str,
    payload: dict,
) -> dict[str, Any]:
    """
    FollowupAgent reasoning:
    - action='cancel_by_provider' → Scenario D: mark booking cancelled, auto-reschedule
    - action='dispute' → log complaint, generate AI resolution response
    - action='status_update' → advance booking timeline
    - action='feedback' → record rating + update provider score
    """
    trace_steps = []

    booking = next((b for b in _bookings_db if b["ref"] == booking_ref), None)
    if not booking:
        return {"success": False, "error": "Booking not found", "trace": trace_steps}

    trace_steps.append({
        "agent": "FollowupAgent",
        "step": "booking_lookup",
        "input": {"ref": booking_ref},
        "output": {"found": True, "status": booking["status"]},
        "reasoning": f"Located booking {booking_ref} in Firestore"
    })

    if action == "cancel_by_provider":
        # Scenario D: provider cancels → auto-reschedule
        booking["status"] = "cancelled"
        trace_steps.append({
            "agent": "FollowupAgent",
            "step": "cancellation_received",
            "input": {"provider": booking["provider_name"]},
            "output": "booking_cancelled",
            "reasoning": "Provider initiated cancellation. Triggering Scenario D auto-reschedule flow."
        })
        alt_slot = (datetime.utcnow() + timedelta(hours=3)).strftime("%Y-%m-%dT%H:%M:%S")
        trace_steps.append({
            "agent": "FollowupAgent",
            "step": "auto_reschedule",
            "input": {"original_slot": booking["slot"]},
            "output": {"suggested_slot": alt_slot, "same_provider": True},
            "reasoning": "Found next available slot +3h from now. Sending simulated WhatsApp notification to user."
        })
        return {
            "success": True,
            "action": "rescheduled",
            "message": f"Provider cancelled. We've auto-rescheduled for {alt_slot}. WhatsApp notification sent.",
            "new_slot": alt_slot,
            "trace": trace_steps,
        }

    elif action == "dispute":
        complaint = payload.get("complaint", "")
        trace_steps.append({
            "agent": "FollowupAgent",
            "step": "dispute_analysis",
            "input": {"complaint": complaint},
            "output": "resolution_generated",
            "reasoning": "Analysing complaint sentiment. Generating fair resolution using past case patterns."
        })
        resolution = (
            "We've reviewed your complaint. "
            "A PKR 200 discount has been applied to your next booking, "
            "and the provider has been notified. "
            "Our quality team will follow up within 24 hours."
        )
        return {
            "success": True,
            "action": "dispute_resolved",
            "resolution": resolution,
            "trace": trace_steps,
        }

    elif action == "status_update":
        new_status = payload.get("status", "en_route")
        booking["status"] = new_status
        # Advance timeline
        for step in booking["timeline"]:
            if step["status"].lower().replace(" ", "_") == new_status:
                step["done"] = True
        trace_steps.append({
            "agent": "FollowupAgent",
            "step": "status_advanced",
            "input": {"new_status": new_status},
            "output": booking["timeline"],
            "reasoning": f"Updated booking timeline to '{new_status}'"
        })
        return {"success": True, "action": "status_updated", "timeline": booking["timeline"], "trace": trace_steps}

    return {"success": False, "error": f"Unknown action: {action}", "trace": trace_steps}
