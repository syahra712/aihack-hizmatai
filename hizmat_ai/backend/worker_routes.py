"""
worker_routes.py — Worker-side API endpoints for HizmatAI.
All routes require Firebase Auth token (verified via firebase-admin).
"""
import os
from datetime import datetime
from typing import Optional, Any

from fastapi import APIRouter, HTTPException, Request, Depends
from pydantic import BaseModel

router = APIRouter(prefix="/worker", tags=["Worker"])

# ── Auth middleware ────────────────────────────────────────────────
def get_firebase_db():
    """Returns Firestore client. Initialized once in main.py."""
    try:
        from firebase_admin import firestore as fs
        return fs.client()
    except Exception:
        raise HTTPException(status_code=503, detail="Firestore not initialized")

async def verify_worker_token(request: Request) -> dict:
    """Verify Firebase ID token from Authorization header."""
    try:
        from firebase_admin import auth
        token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()
        if not token:
            raise HTTPException(status_code=401, detail="Missing Authorization header")
        decoded = auth.verify_id_token(token)
        request.state.uid = decoded["uid"]
        return decoded
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

# ── Request models ─────────────────────────────────────────────────
class RegisterWorkerRequest(BaseModel):
    profile: dict

class UpdateProfileRequest(BaseModel):
    fields: dict

class AvailabilityRequest(BaseModel):
    is_available: bool
    lat: Optional[float] = None
    lng: Optional[float] = None

class DeclineRequest(BaseModel):
    reason: str

class StatusUpdateRequest(BaseModel):
    new_status: str
    timestamp_field: Optional[str] = None

class ExtraWorkRequest(BaseModel):
    description: str
    amount: float

class ChatSendRequest(BaseModel):
    text: str
    sender: str = "worker"

class RatingReplyRequest(BaseModel):
    reply: str

# ── Profile endpoints ──────────────────────────────────────────────
@router.post("/register")
async def register_worker(
    req: RegisterWorkerRequest,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Create Firestore provider document after Firebase Auth signup."""
    profile = req.profile
    profile["uid"] = token["uid"]
    profile["registered_at"] = datetime.utcnow().isoformat()
    profile["last_active"] = datetime.utcnow().isoformat()
    profile.setdefault("is_verified", False)
    profile.setdefault("is_suspended", False)
    profile.setdefault("total_jobs", 0)
    profile.setdefault("rating", 0.0)
    profile.setdefault("review_count", 0)
    profile.setdefault("on_time_score", 1.0)
    profile.setdefault("cancellation_rate", 0.0)
    profile.setdefault("completion_rate", 1.0)
    profile.setdefault("avg_response_seconds", 0)
    worker_id = profile.get("id") or f"prov_{token['uid'][:8]}"
    profile["id"] = worker_id
    db.collection("providers").document(worker_id).set(profile)
    return {"success": True, "worker_id": worker_id}

@router.get("/profile")
async def get_profile(
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Read provider doc by Firebase UID."""
    results = db.collection("providers").where("uid", "==", token["uid"]).limit(1).get()
    if not results:
        raise HTTPException(status_code=404, detail="Worker profile not found")
    return results[0].to_dict()

@router.put("/profile")
async def update_profile(
    req: UpdateProfileRequest,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Update provider doc fields."""
    results = db.collection("providers").where("uid", "==", token["uid"]).limit(1).get()
    if not results:
        raise HTTPException(status_code=404, detail="Worker profile not found")
    doc_id = results[0].id
    db.collection("providers").document(doc_id).update(req.fields)
    return {"success": True}

@router.put("/availability")
async def update_availability(
    req: AvailabilityRequest,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Toggle is_available + update lat/lng."""
    results = db.collection("providers").where("uid", "==", token["uid"]).limit(1).get()
    if not results:
        raise HTTPException(status_code=404, detail="Worker profile not found")
    doc_id = results[0].id
    update_data: dict[str, Any] = {
        "is_available": req.is_available,
        "last_active": datetime.utcnow().isoformat(),
    }
    if req.lat is not None and req.lng is not None:
        # Basic GPS spoof detection
        existing = results[0].to_dict()
        if existing.get("lat") and existing.get("last_location_update"):
            pass  # Could add haversine check here
        update_data["lat"] = req.lat
        update_data["lng"] = req.lng
        update_data["last_location_update"] = datetime.utcnow().isoformat()
    db.collection("providers").document(doc_id).update(update_data)
    return {"success": True, "is_available": req.is_available}

# ── Job endpoints ──────────────────────────────────────────────────
@router.post("/jobs/{ref}/accept")
async def accept_job(
    ref: str,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Firestore transaction: check status == pending_worker, set en_route."""
    from firebase_admin import firestore as fs
    booking_ref_doc = db.collection("bookings").document(ref)

    @fs.transactional
    def _accept_txn(transaction, doc_ref):
        snap = doc_ref.get(transaction=transaction)
        if not snap.exists:
            raise HTTPException(status_code=404, detail="Booking not found")
        data = snap.to_dict()
        if data.get("status") != "pending_worker":
            return {"success": False, "reason": "job_already_taken"}
        now_iso = datetime.utcnow().isoformat()
        timeline = data.get("timeline", [])
        for step in timeline:
            if step.get("status") == "En Route":
                step["done"] = True
                step["at"] = now_iso
        transaction.update(doc_ref, {
            "status": "en_route",
            "accepted_at": now_iso,
            "timeline": timeline,
            "updated_at": now_iso,
        })
        return {"success": True}

    transaction = db.transaction()
    result = _accept_txn(transaction, booking_ref_doc)
    return result

@router.post("/jobs/{ref}/decline")
async def decline_job(
    ref: str,
    req: DeclineRequest,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Record decline, re-run RankAgent with excluded_providers, reassign."""
    from firebase_admin import firestore as fs

    booking_doc = db.collection("bookings").document(ref)
    booking = booking_doc.get().to_dict()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    now_iso = datetime.utcnow().isoformat()
    booking_doc.update({
        "declined_by": fs.ArrayUnion([{
            "provider_id": token["uid"],
            "reason": req.reason,
            "at": now_iso,
        }]),
        "assignment_attempts": fs.Increment(1),
        "updated_at": now_iso,
    })

    # Collect all declined provider IDs
    declined_ids = [d["provider_id"] for d in booking.get("declined_by", [])]
    declined_ids.append(token["uid"])

    # Re-run RankAgent
    try:
        from agents import run_rank_agent
        all_providers = [p.to_dict() for p in db.collection("providers").where("is_available", "==", True).get()]
        ranked_result = run_rank_agent(
            providers=all_providers,
            user_lat=booking.get("customer_lat", 24.8040),
            user_lng=booking.get("customer_lng", 67.0708),
            service_type=booking.get("service_type", ""),
            excluded_providers=declined_ids,
        )
        ranked = ranked_result.get("ranked", [])
        if ranked:
            next_provider = ranked[0]
            booking_doc.update({
                "provider_id": next_provider["id"],
                "provider_name": next_provider["name"],
                "status": "pending_worker",
                "updated_at": now_iso,
            })
            return {"success": True, "reassigned_to": next_provider["id"]}
        else:
            booking_doc.update({"status": "no_provider_available", "updated_at": now_iso})
            return {"success": True, "reassigned_to": None}
    except Exception as e:
        return {"success": False, "error": str(e)}

@router.put("/jobs/{ref}/status")
async def update_job_status(
    ref: str,
    req: StatusUpdateRequest,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Advance timeline step + set corresponding timestamp."""
    booking_doc = db.collection("bookings").document(ref)
    booking = booking_doc.get().to_dict()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    now_iso = datetime.utcnow().isoformat()
    timeline = booking.get("timeline", [])
    for step in timeline:
        if step.get("status", "").lower().replace(" ", "_") == req.new_status.lower().replace(" ", "_"):
            step["done"] = True
            step["at"] = now_iso

    update_data: dict[str, Any] = {
        "status": req.new_status,
        "timeline": timeline,
        "updated_at": now_iso,
    }
    if req.timestamp_field:
        update_data[req.timestamp_field] = now_iso

    # Status-specific notifications / logic
    if req.new_status == "completed":
        update_data["completed_at"] = now_iso
        # Trigger performance recalculation async
        _schedule_perf_recalc(token["uid"], db)

    booking_doc.update(update_data)
    return {"success": True, "new_status": req.new_status}

@router.post("/jobs/{ref}/extra")
async def add_extra_work(
    ref: str,
    req: ExtraWorkRequest,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Add extra work line item (pending customer approval)."""
    from firebase_admin import firestore as fs
    now_iso = datetime.utcnow().isoformat()
    db.collection("bookings").document(ref).update({
        "extra_work": fs.ArrayUnion([{
            "description": req.description,
            "amount": req.amount,
            "approved": False,
            "requested_at": now_iso,
        }]),
        "updated_at": now_iso,
    })
    return {"success": True}

@router.get("/jobs/active")
async def get_active_jobs(
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Query bookings where provider_id=me AND status in [en_route, arrived, in_progress]."""
    results = db.collection("bookings") \
        .where("provider_id", "==", token["uid"]) \
        .where("status", "in", ["en_route", "arrived", "in_progress"]) \
        .get()
    return {"jobs": [r.to_dict() for r in results]}

@router.get("/jobs/history")
async def get_job_history(
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
    limit: int = 20,
):
    """Paginated completed/cancelled bookings."""
    results = db.collection("bookings") \
        .where("provider_id", "==", token["uid"]) \
        .where("status", "in", ["completed", "cancelled"]) \
        .order_by("created_at", direction="DESCENDING") \
        .limit(limit) \
        .get()
    return {"jobs": [r.to_dict() for r in results]}

# ── Earnings endpoints ─────────────────────────────────────────────
@router.get("/earnings/summary")
async def get_earnings_summary(
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Aggregate earnings by today/week/month."""
    from datetime import timezone
    from datetime import timedelta as td
    now = datetime.utcnow()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
    week_start = (now - td(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0).isoformat()

    def _sum(since_iso):
        results = db.collection("earnings") \
            .where("worker_id", "==", token["uid"]) \
            .where("created_at", ">=", since_iso) \
            .get()
        return sum(r.to_dict().get("net_amount", 0) for r in results)

    return {
        "today": _sum(today_start),
        "week": _sum(week_start),
        "month": _sum(month_start),
    }

@router.get("/earnings/history")
async def get_earnings_history(
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
    limit: int = 30,
):
    """Paginated earnings list."""
    results = db.collection("earnings") \
        .where("worker_id", "==", token["uid"]) \
        .order_by("created_at", direction="DESCENDING") \
        .limit(limit) \
        .get()
    return {"earnings": [r.to_dict() for r in results]}

# ── Ratings endpoints ──────────────────────────────────────────────
@router.get("/ratings")
async def get_ratings(
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Query bookings where customer_rating != null for this worker."""
    # Firestore doesn't support != null directly; query where customer_rating > 0
    results = db.collection("bookings") \
        .where("provider_id", "==", token["uid"]) \
        .where("customer_rating", ">", 0) \
        .order_by("customer_rating", direction="DESCENDING") \
        .order_by("created_at", direction="DESCENDING") \
        .get()
    return {"ratings": [r.to_dict() for r in results]}

@router.post("/ratings/{ref}/reply")
async def reply_to_rating(
    ref: str,
    req: RatingReplyRequest,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Update worker_reply field on booking."""
    db.collection("bookings").document(ref).update({
        "worker_reply": req.reply,
        "updated_at": datetime.utcnow().isoformat(),
    })
    return {"success": True}

# ── Chat endpoints ─────────────────────────────────────────────────
@router.post("/chat/{ref}/send")
async def send_chat_message(
    ref: str,
    req: ChatSendRequest,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Add message to bookings/{ref}/messages sub-collection."""
    import uuid as _uuid
    msg_id = str(_uuid.uuid4())
    db.collection("bookings").document(ref).collection("messages").document(msg_id).set({
        "id": msg_id,
        "sender": req.sender,
        "text": req.text,
        "translated_text": None,
        "sent_at": datetime.utcnow().isoformat(),
        "read": False,
    })
    return {"success": True, "message_id": msg_id}

@router.get("/chat/{ref}/history")
async def get_chat_history(
    ref: str,
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Read messages sub-collection."""
    results = db.collection("bookings").document(ref).collection("messages") \
        .order_by("sent_at") \
        .get()
    return {"messages": [r.to_dict() for r in results]}

# ── Performance endpoint ───────────────────────────────────────────
@router.get("/performance")
async def get_performance(
    token: dict = Depends(verify_worker_token),
    db=Depends(get_firebase_db),
):
    """Read performance metrics from provider doc."""
    results = db.collection("providers").where("uid", "==", token["uid"]).limit(1).get()
    if not results:
        raise HTTPException(status_code=404, detail="Profile not found")
    data = results[0].to_dict()
    return {
        "rating": data.get("rating", 0),
        "total_jobs": data.get("total_jobs", 0),
        "on_time_score": data.get("on_time_score", 1.0),
        "cancellation_rate": data.get("cancellation_rate", 0.0),
        "completion_rate": data.get("completion_rate", 1.0),
        "avg_response_seconds": data.get("avg_response_seconds", 0),
    }

# ── Helper: schedule performance recalculation ─────────────────────
def _schedule_perf_recalc(worker_uid: str, db) -> None:
    """Recalculate worker performance metrics after job completion."""
    try:
        from datetime import timedelta
        bookings = db.collection("bookings") \
            .where("provider_id", "==", worker_uid) \
            .where("status", "in", ["completed", "cancelled"]) \
            .get()

        total = len(bookings)
        completed = sum(1 for b in bookings if b.to_dict().get("status") == "completed")
        cancelled = total - completed
        ratings = [
            b.to_dict()["customer_rating"] for b in bookings
            if b.to_dict().get("customer_rating") is not None
        ]

        update_data = {
            "total_jobs": completed,
            "completion_rate": completed / max(total, 1),
            "cancellation_rate": cancelled / max(total, 1),
            "last_active": datetime.utcnow().isoformat(),
        }
        if ratings:
            update_data["rating"] = sum(ratings) / len(ratings)
            update_data["review_count"] = len(ratings)

        results = db.collection("providers").where("uid", "==", worker_uid).limit(1).get()
        if results:
            db.collection("providers").document(results[0].id).update(update_data)
    except Exception:
        pass  # Non-critical — will recalc on next completion
