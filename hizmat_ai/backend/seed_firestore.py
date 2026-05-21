#!/usr/bin/env python3
"""
seed_firestore.py — Run once to migrate providers.json into Firestore.
Usage: python seed_firestore.py
Requires: serviceAccountKey.json in same directory
"""
import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("ERROR: firebase-admin not installed. Run: pip install firebase-admin")
    sys.exit(1)

SERVICE_ACCOUNT_PATH = Path(__file__).parent / "serviceAccountKey.json"
PROVIDERS_JSON_PATH = Path(__file__).parent / "providers.json"

def main():
    if not SERVICE_ACCOUNT_PATH.exists():
        print(f"ERROR: {SERVICE_ACCOUNT_PATH} not found.")
        print("Download from: Firebase Console → Project Settings → Service accounts → Generate new private key")
        sys.exit(1)

    if not PROVIDERS_JSON_PATH.exists():
        print(f"ERROR: {PROVIDERS_JSON_PATH} not found.")
        sys.exit(1)

    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    with open(PROVIDERS_JSON_PATH) as f:
        providers = json.load(f)

    now = datetime.utcnow()
    slot_offsets = [
        timedelta(days=1, hours=9),
        timedelta(days=1, hours=14),
        timedelta(days=2, hours=10),
    ]
    base_date = now.replace(hour=0, minute=0, second=0, microsecond=0)

    seeded = 0
    failed = 0

    for p in providers:
        try:
            # Refresh slots to future dates
            p["available_slots"] = [
                (base_date + offset).strftime("%Y-%m-%dT%H:%M:%S")
                for offset in slot_offsets
            ]
            # Add worker-app fields if missing
            p.setdefault("uid", None)
            p.setdefault("phone", None)
            p.setdefault("cnic", None)
            p.setdefault("profile_photo_url", None)
            p.setdefault("city", _infer_city(p.get("zone", "")))
            p.setdefault("last_location_update", None)
            p.setdefault("is_on_job", False)
            p.setdefault("vacation_mode", False)
            p.setdefault("vacation_start", None)
            p.setdefault("vacation_end", None)
            p.setdefault("buffer_minutes", 30)
            p.setdefault("is_verified", True)
            p.setdefault("is_suspended", False)
            p.setdefault("completion_rate", round(1.0 - p.get("cancellation_rate", 0.03), 2))
            p.setdefault("avg_response_seconds", 25)
            p.setdefault("certifications", p.get("specializations", [])[:1])
            p.setdefault("payout_method", "jazzcash")
            p.setdefault("payout_account", None)
            p.setdefault("app_version", "1.0.0")
            p["registered_at"] = firestore.SERVER_TIMESTAMP
            p["last_active"] = firestore.SERVER_TIMESTAMP

            db.collection("providers").document(p["id"]).set(p)
            print(f"  ✓ {p['id']} — {p['name']} ({p['service_type']}, {p.get('city','?')})")
            seeded += 1
        except Exception as e:
            print(f"  ✗ {p.get('id', '?')} — ERROR: {e}")
            failed += 1

    print(f"\nDone: {seeded} seeded, {failed} failed")

def _infer_city(zone: str) -> str:
    zone_lower = zone.lower()
    if any(k in zone_lower for k in ["lahore", "johar", "model town", "gulberg"]):
        return "Lahore"
    if any(k in zone_lower for k in ["islamabad", "g-13", "f-10", "i-8", "bahria"]):
        return "Islamabad"
    return "Karachi"

if __name__ == "__main__":
    main()
