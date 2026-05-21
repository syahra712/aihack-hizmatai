# System Architect Prompt — HizmatAI Worker-Side Mobile Application (Firestore Edition)

You are a Principal Mobile System Architect with 15+ years of experience building two-sided marketplace platforms (Uber, TaskRabbit, UrbanClap/Urban Company scale). You are tasked with designing and implementing the complete WORKER-SIDE (service provider) application for HizmatAI — an AI-agentic home service booking platform targeting Pakistan's informal economy.

**Database: Firebase Firestore (NoSQL, real-time, offline-capable)**
**Auth: Firebase Phone Authentication (real OTP)**
**Platform: Flutter (Android APK + Web)**

---

## SECTION 1 — EXISTING SYSTEM CONTEXT (DO NOT REBUILD)

The CUSTOMER SIDE is already fully built. Your worker app must integrate with (not replace) the following:

### 1.1 — Backend (FastAPI, Python)
- Entry: `/hizmat_ai/backend/main.py` on port 8000
- Orchestration: Google ADK (Gemini 2.5 Flash) with 6-agent pipeline
- Agents in `/hizmat_ai/backend/agents.py`:
  - ① IntentAgent — NLP parsing (Urdu script, Roman Urdu, English, mixed)
  - ② DiscoveryAgent — Provider filtering by service_type, zone, availability
  - ③ RankAgent — 6-factor weighted scoring (distance 20%, rating 25%, reliability 20%, specialization 15%, price 10%, cancellation 10%)
  - ④ PriceAgent — dynamic pricing (base, urgency 20%, distance PKR50/km>5km, peak 15%, loyalty -5%, minimum PKR100)
  - ⑤ BookingAgent — Conflict detection, ref generation (`HMZ-{8-char uppercase hex}`, e.g. `HMZ-1A2B3C4D`), timeline milestones
  - ⑥ FollowupAgent — Reminders, status updates, cancellation recovery, disputes
- ADK orchestrator: `/hizmat_ai/backend/adk_orchestrator.py` — wraps all 6 agents in an LlmAgent, maintains its own `_sessions` dict per session_id (this file also needs Firestore migration, see Section 4)
- Distance: Haversine formula (`haversine.py`), no Maps API
- Payments: Stripe test mode (sandbox key)
- **Key existing function signatures** (do not change these signatures, only extend them):
  - `run_rank_agent(providers, user_lat, user_lng, service_type, specialization, requested_slot, budget_max, excluded_providers)` — already accepts `excluded_providers: list[str] | None`
  - `run_price_agent(provider, hours, is_urgent, distance_km, peak_hour)` — returns `{breakdown: {base, urgency_fee, distance_fee, surge_fee, discount, total, currency, hours_estimated}, trace}`
  - `run_booking_agent(provider, slot, user_id, service_type, price_breakdown)` — writes to `_bookings_db` in-memory list
  - `refresh_provider_slots(providers)` — already regenerates `available_slots` as a rolling 3-slot window from `datetime.utcnow()` (no stale date problem at runtime)

### 1.2 — Customer Flutter App
- `/hizmat_ai/flutter_app/` — Riverpod state, GoRouter navigation, SharedPreferences persistence
- **Firebase already configured**: `pubspec.yaml` includes `firebase_core`, `firebase_auth`, `cloud_firestore`; `firebase_options.dart` exists and is linked to project `hizmatai`
- Services: `api_service.dart` (HTTP to /chat), `booking_service.dart` (local persistence), `mock_ai_service.dart` (offline fallback with 26 providers)
- Models: `ServiceProvider`, `Booking` (with BookingStatus enum), `ChatMessage`
- Theme: Light morphism, Primary #00B894 (mint), Accent #6C5CE7 (purple), Poppins font

### 1.3 — Customer React Web App
- `/src/` — Vite + React 18, full 6-agent engine reimplemented in JavaScript (`src/agents/agentEngine.js`)
- Two-phase flow: Phase 1 (discover + rank top 3) → Phase 2 (price + book)
- Agent trace transparency panel, Stripe payment, booking history
- **Provider schema in `agentEngine.js` uses different field names than the backend** (`pricePerHr` vs `hourly_rate`, `completionRate` vs `completion_rate`, `responseTime` vs `avg_response_seconds`, `certified: bool` vs `certifications: []`, `area` vs `zone`). After Firestore migration, update `agentEngine.js`'s PROVIDERS_DB to match Firestore field names or add a mapping shim in `agentEngine.js` when reading from Firestore.
- Firebase config: `/src/firebase.js` — project ID `hizmatai`, already initialized

### 1.4 — Provider Data Schema (current — will migrate to Firestore)

```json
{
  "id": "prov_001",
  "name": "Usman AC & Cooling",
  "service_type": "ac_repair",
  "zone": "DHA Phase 2",
  "lat": 24.8040, "lng": 67.0708,
  "rating": 4.8,
  "on_time_score": 0.95,
  "cancellation_rate": 0.03,
  "hourly_rate": 1200,
  "specializations": ["split_ac", "window_ac", "gas_refilling"],
  "available_slots": ["2026-05-21T09:00:00"],
  "is_available": true,
  "total_jobs": 342,
  "review_count": 189
}
```

### 1.5 — Booking Object Shape (current — will migrate to Firestore)

```json
{
  "ref": "HMZ-1A2B3C4D",
  "provider_id": "P001",
  "provider_name": "Ustad Tariq",
  "slot": "2026-05-21T10:00:00",
  "status": "confirmed",
  "price": 2154,
  "service_type": "electrician",
  "timeline": [
    {"status": "Confirmed", "done": true},
    {"status": "Reminder Sent", "done": false},
    {"status": "En Route", "done": false},
    {"status": "Completed", "done": false}
  ]
}
```

### 1.6 — Service Categories
Active (6): electrician, plumber, ac_repair, home_cleaning, home_tutor, beautician
Unsupported (guard exists): painter, carpenter

### 1.7 — Geographic Coverage
Cities: Karachi (15+ providers), Lahore (5+), Islamabad (5+)
Zones: DHA Phase 2, Gulshan-e-Iqbal, PECHS, Clifton, North Nazimabad, Bahria Town, G-13, F-10, Johar Town, Model Town, etc.

### 1.8 — Existing Firebase & Firestore Files (DO NOT OVERWRITE — MERGE)
- `/firebase.json` — already exists (Firestore rules + indexes config)
- `/firestore.rules` — already exists (base RBAC rules for customer app)
- `/firestore.indexes.json` — already exists (indexes for users, bookings, providers)
- `/.firebaserc` — already exists, default project is `hizmatai`

All Firestore rule and index additions for the worker app must be **merged into these existing files**, not replace them.

---

## SECTION 2 — FIREBASE ARCHITECTURE (NEW — CORE OF EVERYTHING)

### 2.1 — Firebase Project (Already Created)

```
Project ID: hizmatai
Auth domain: hizmatai.firebaseapp.com
Services enabled:
  - Firestore Database (Native mode, asia-south1 region)
  - Firebase Authentication (Phone provider enabled)
  - Firebase Storage (for photos — optional, can use base64 for hackathon)
```

The Flutter customer app already has `firebase_options.dart` configured for this project. The worker app must use the **same project** — copy `firebase_options.dart` from `/hizmat_ai/flutter_app/lib/firebase_options.dart` into the worker app and reuse the same `google-services.json`.

### 2.2 — Firestore Collections Schema

#### Collection: `providers` (replaces providers.json)

```
/providers/{provider_id}
{
  // Identity
  "id": "prov_001",
  "uid": "firebase_auth_uid",           // ← links to Firebase Auth user
  "name": "Usman AC & Cooling",
  "phone": "+923001234567",
  "cnic": "42101-1234567-1",            // encrypted at rest
  "profile_photo_url": "https://...",

  // Service config
  "service_type": "ac_repair",
  "specializations": ["split_ac", "window_ac", "gas_refilling"],
  "hourly_rate": 1200,                  // PKR
  "certifications": ["HVAC Level 2"],

  // Location
  "city": "Karachi",
  "zone": "DHA Phase 2",
  "lat": 24.8040,
  "lng": 67.0708,
  "last_location_update": Timestamp,

  // Availability
  "is_available": true,                  // online/offline toggle
  "is_on_job": false,                    // true when actively working
  "vacation_mode": false,
  "vacation_start": null,
  "vacation_end": null,
  "available_slots": ["2026-05-21T09:00", "2026-05-21T14:00"],
  "buffer_minutes": 30,                 // gap between jobs

  // Performance (auto-calculated after each job)
  "rating": 4.8,
  "review_count": 189,
  "total_jobs": 342,
  "on_time_score": 0.95,                // % arrived within 10 min of ETA
  "cancellation_rate": 0.03,            // % of accepted jobs cancelled by worker
  "completion_rate": 0.97,              // % of accepted jobs completed
  "avg_response_seconds": 25,           // time to accept/decline

  // Payout
  "payout_method": "jazzcash",          // jazzcash | easypaisa | bank
  "payout_account": "03001234567",

  // Metadata
  "registered_at": Timestamp,
  "last_active": Timestamp,
  "app_version": "1.0.0",
  "is_verified": true,                  // admin-approved
  "is_suspended": false
}
```

#### Collection: `bookings` (replaces `_bookings_db` in-memory list)

```
/bookings/{booking_ref}
{
  "ref": "HMZ-1A2B3C4D",               // 8-char uppercase hex after HMZ-
  "customer_id": "demo_user",
  "customer_name": "Ahmed",
  "provider_id": "prov_001",
  "provider_name": "Ustad Tariq",
  "service_type": "electrician",
  "city": "Karachi",
  "zone": "DHA Phase 2",

  // Location
  "customer_lat": 24.8607,
  "customer_lng": 67.0011,
  "customer_address": "House 45, Street 12, DHA Phase 2",
  "distance_km": 2.3,

  // Timing
  "slot": Timestamp,
  "accepted_at": Timestamp | null,
  "arrived_at": Timestamp | null,
  "started_at": Timestamp | null,
  "completed_at": Timestamp | null,
  "cancelled_at": Timestamp | null,

  // Status
  "status": "confirmed",
  // enum: pending_worker | confirmed | en_route | arrived | in_progress | completed | cancelled | disputed

  // Price — run_price_agent() output + two fields appended by BookingAgent on write
  "price_breakdown": {
    "base": 1600,
    "urgency_fee": 320,
    "distance_fee": 100,
    "surge_fee": 0,
    "discount": -96,
    "platform_fee": 99,                 // flat PKR 99, added by BookingAgent (NOT in PriceAgent output)
    "tax_gst": 131,                     // 5% of (subtotal - discount + platform_fee), added by BookingAgent
    "total": 2154,                      // includes platform_fee + tax_gst
    "currency": "PKR",
    "hours_estimated": 2
  },
  "actual_hours": null,
  "extra_work": [],                      // [{description, amount, approved}]
  "final_price": null,                   // set on completion if differs

  // Payment
  "payment_status": "pending",           // pending | paid | failed | refunded
  "stripe_payment_intent_id": null,

  // Evidence
  "photos_before": [],                   // URLs or base64
  "photos_after": [],
  "materials_used": [],

  // Timeline (for UI stepper — both apps read this)
  "timeline": [
    {"status": "Confirmed", "done": true, "at": Timestamp},
    {"status": "En Route", "done": false, "at": null},
    {"status": "Arrived", "done": false, "at": null},
    {"status": "In Progress", "done": false, "at": null},
    {"status": "Completed", "done": false, "at": null}
  ],

  // Decline tracking
  "declined_by": [],                     // [{provider_id, reason, at}]
  "assignment_attempts": 1,

  // Follow-up
  "customer_rating": null,               // 1-5
  "customer_review": null,
  "worker_reply": null,
  "dispute": null,                       // {reason, status, resolution, credit_amount}

  // Metadata
  "created_at": Timestamp,
  "updated_at": Timestamp,
  "is_urgent": false,
  "language": "roman_urdu"
}
```

> **Important — PriceAgent output vs Firestore booking schema**: `run_price_agent()` currently returns `{base, urgency_fee, distance_fee, surge_fee, discount, total, currency, hours_estimated}`. It does NOT compute `platform_fee` or `tax_gst`. The `BookingAgent` (in `run_booking_agent()`) must append these two fields when writing to Firestore:
> ```python
> platform_fee = 99
> tax_gst = round((breakdown["total"] - abs(breakdown["discount"]) + platform_fee) * 0.05)
> breakdown["platform_fee"] = platform_fee
> breakdown["tax_gst"] = tax_gst
> breakdown["total"] = breakdown["total"] + platform_fee + tax_gst
> ```

#### Collection: `earnings`

```
/earnings/{earning_id}
{
  "id": "earn_001",
  "worker_id": "prov_001",
  "booking_ref": "HMZ-1A2B3C4D",
  "service_type": "electrician",

  "gross_amount": 2154,                 // total from customer
  "platform_fee": 99,                   // deducted
  "net_amount": 2055,                   // worker receives

  "status": "cleared",                  // pending | cleared | disputed | paid_out
  "cleared_at": Timestamp,
  "payout_ref": "PAY-xxxx",

  "created_at": Timestamp
}
```

#### Collection: `chat_messages` (sub-collection under bookings)

```
/bookings/{booking_ref}/messages/{message_id}
{
  "id": "msg_001",
  "sender": "worker",                   // worker | customer | system
  "text": "آ رہا ہوں",
  "translated_text": "On my way",
  "sent_at": Timestamp,
  "read": false
}
```

#### Collection: `notifications`

```
/notifications/{notification_id}
{
  "id": "notif_001",
  "worker_id": "prov_001",
  "type": "new_job",
  // types: new_job | booking_confirmed | customer_cancelled | payment_received |
  //        rating_received | reminder | earnings_summary | platform_announcement
  "title": "New Job Available",
  "body": "Electrician needed in DHA Phase 2 — PKR 2,154",
  "data": {"booking_ref": "HMZ-1A2B3C4D"},
  "read": false,
  "created_at": Timestamp
}
```

#### Collection: `sessions` (replaces `_session_contexts` in agents.py AND `_sessions` in adk_orchestrator.py)

```
/sessions/{session_id}
{
  "user_id": "demo_user",
  "last_intent": {...},
  "last_ranked": [...],
  "last_booking": {...},
  "language": "roman_urdu",
  "created_at": Timestamp,
  "updated_at": Timestamp
}
```

### 2.3 — Firestore Security Rules (MERGE into existing `/firestore.rules`)

```javascript
// ADD these match blocks inside the existing rules_version = '2' service block
// Do NOT replace the existing customer-side rules

// Providers: worker can read/write own profile, anyone can read (agents need full access)
match /providers/{providerId} {
  allow read: if true;
  allow write: if request.auth != null && request.auth.uid == resource.data.uid;
}

// Bookings: customer + assigned worker can read; worker can advance status only
match /bookings/{bookingRef} {
  allow read: if request.auth != null &&
    (request.auth.uid == resource.data.customer_id ||
     request.auth.uid == resource.data.provider_id);
  allow update: if request.auth != null &&
    request.auth.uid == resource.data.provider_id &&
    request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['status', 'timeline', 'accepted_at', 'arrived_at',
                'started_at', 'completed_at', 'photos_before', 'photos_after']);
  allow create: if false; // only backend creates bookings

  match /messages/{messageId} {
    allow read: if request.auth != null;
    allow create: if request.auth != null;
  }
}

// Earnings: worker reads own only, backend writes
match /earnings/{earningId} {
  allow read: if request.auth != null && request.auth.uid == resource.data.worker_id;
  allow write: if false;
}

// Notifications: worker reads/marks-read own only, backend creates
match /notifications/{notifId} {
  allow read: if request.auth != null && request.auth.uid == resource.data.worker_id;
  allow update: if request.auth != null && request.auth.uid == resource.data.worker_id
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
  allow create: if false;
}

// Sessions: admin SDK only
match /sessions/{sessionId} {
  allow read, write: if false;
}
```

### 2.4 — Real-Time Listeners (Firestore Snapshots)

No polling, no WebSocket server. Firestore fires natively:

```dart
// WORKER APP — Listen for incoming jobs assigned to this worker
FirebaseFirestore.instance
  .collection('bookings')
  .where('provider_id', isEqualTo: currentWorkerId)
  .where('status', isEqualTo: 'pending_worker')
  .snapshots()
  .listen((snapshot) {
    for (var doc in snapshot.docChanges) {
      if (doc.type == DocumentChangeType.added) {
        showIncomingJobOverlay(doc.doc.data());
      }
    }
  });

// CUSTOMER APP — Listen for worker status updates (add to existing customer app)
FirebaseFirestore.instance
  .collection('bookings')
  .doc(bookingRef)
  .snapshots()
  .listen((snapshot) {
    updateTimeline(snapshot.data()!['timeline']);
  });
```

**What this replaces:**
- No WebSocket server needed
- No polling endpoints needed
- No manual push notification wiring for status updates
- Works offline automatically (Firestore caches locally, syncs when back online)

### 2.5 — Backend Migration (FastAPI → Firestore)

Add `firebase-admin` to `/hizmat_ai/backend/requirements.txt`:

```
firebase-admin>=6.0.0
```

Initialize in `main.py`:

```python
import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()
```

**Migration mapping — swap these in `agents.py` AND `adk_orchestrator.py`:**

| Before (in-memory) | After (Firestore) |
|---|---|
| `providers = json.load(open("providers.json"))` | `db.collection("providers").where("is_available", "==", True).get()` |
| `_bookings_db.append(booking)` | `db.collection("bookings").document(ref).set(booking)` |
| `_session_contexts[sid] = ctx` (agents.py) | `db.collection("sessions").document(sid).set(ctx)` |
| `_sessions[sid] = ...` (adk_orchestrator.py) | `db.collection("sessions").document(sid).set(ctx)` |
| `for b in _bookings_db if b["provider_id"] == pid` | `db.collection("bookings").where("provider_id", "==", pid).get()` |

**Keep all existing agent logic identical** — only swap the read/write layer. The 6-agent pipeline, scoring formula, pricing components, conflict detection, and `refresh_provider_slots()` all stay the same.

**Seeding script** — run once on first backend boot to migrate `providers.json` into Firestore:

```python
# seed_firestore.py — run with: python seed_firestore.py
import json, firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

with open("providers.json") as f:
    providers = json.load(f)

# Regenerate slots to future dates (mirrors refresh_provider_slots() logic)
now = datetime.utcnow()
offsets = [timedelta(days=1, hours=9), timedelta(days=1, hours=14), timedelta(days=2, hours=10)]

for p in providers:
    p["available_slots"] = [
        (now.replace(hour=0, minute=0, second=0) + o).strftime("%Y-%m-%dT%H:%M:%S")
        for o in offsets
    ]
    p["uid"] = None          # set when worker registers via phone auth
    p["registered_at"] = firestore.SERVER_TIMESTAMP
    p["last_active"] = firestore.SERVER_TIMESTAMP
    p["is_verified"] = True
    p["is_suspended"] = False
    p["completion_rate"] = round(1 - p.get("cancellation_rate", 0.03), 2)
    p["avg_response_seconds"] = 25
    p["certifications"] = p.get("specializations", [])[:1]
    db.collection("providers").document(p["id"]).set(p)
    print(f"Seeded {p['id']} — {p['name']}")
```

---

## SECTION 3 — WORKER APP REQUIREMENTS

Build the complete worker-side Flutter application. The worker app is the provider's daily tool — it must be fast, reliable, work on low-end Android devices (2GB RAM, spotty 3G), and respect the cultural context of Pakistan's service workers (many semi-literate, Urdu-primary).

### 3.1 — Worker Authentication & Onboarding

#### Registration Flow:
- Phone number input with +92 prefix (Pakistan country code)
- Firebase Phone Auth sends real OTP (free tier: 10K/month)
- After OTP verified → multi-step profile setup:
  - Step 1: Name + profile photo (camera or gallery)
  - Step 2: CNIC number with format validation (xxxxx-xxxxxxx-x)
  - Step 3: Service category selection (multi-select from 6 active types)
  - Step 4: Specialization tags (free-form + suggestions from existing data)
  - Step 5: City auto-detect from GPS → zone multi-select
  - Step 6: Hourly rate input (PKR, show market average as hint: "Most electricians in DHA charge PKR 800-1200/hr")
  - Step 7: Available slots setup (weekly recurring calendar picker)
  - Step 8: Payout method (JazzCash / EasyPaisa / bank) + account number
- On complete → write full document to Firestore `/providers/{uid}`

#### Login:
- Phone + OTP via Firebase Auth (no password — workers forget passwords)
- `firebase_auth` package handles session persistence (auto-login until sign out)
- Biometric unlock option after first login (`local_auth` package)

#### Profile Management:
- Edit all registration fields post-setup → Firestore update
- Toggle `is_available` (online/offline switch — prominent, one-tap) → instant Firestore write → DiscoveryAgent immediately stops/starts including this worker
- Update current GPS location → Firestore `lat`, `lng`, `last_location_update` fields
- Upload certifications / portfolio photos
- Set vacation mode (date range → auto-sets `is_available: false`)

### 3.2 — Job Management (Core Loop)

#### Incoming Job Detection:
- **Firestore real-time listener** on `bookings` collection where `provider_id == me` AND `status == "pending_worker"`
- When new document appears → full-screen overlay notification:
  - Service type icon + label
  - Zone name + estimated distance (Haversine from worker's current location)
  - Urgency flag (red pulse animation if urgent)
  - Estimated price (total from price_breakdown)
  - Accept / Decline buttons
  - 60-second auto-decline countdown timer
- Audio alert: distinct sounds for urgent vs normal
- Vibration: long vibration for urgent, short for normal

#### Accept Flow:
- Worker taps Accept →
  1. Firestore transaction (optimistic lock — verify `status == "pending_worker"` before writing)
  2. If already taken: show "Job taken by another worker" toast, dismiss overlay
  3. On success: `status: "en_route"`, `accepted_at: Timestamp.now()`
  4. Update timeline: mark "En Route" as `done: true` with timestamp
  5. Customer app receives real-time update instantly (Firestore listener)
  6. Show ActiveJobScreen with customer first name + address (revealed only after accept), ETA, full price breakdown

#### Decline Flow:
- Worker taps Decline → bottom sheet with reason picker:
  - "Too far" | "Busy right now" | "Can't do this specialization" | "Price too low" | "Other"
- Firestore update: append to `declined_by` array: `{provider_id, reason, at}`
- POST `/worker/jobs/{ref}/decline` → backend re-runs `run_rank_agent()` with `excluded_providers` set to all previously declined provider IDs → updates `provider_id` on the booking → new worker's Firestore listener fires automatically

#### Active Job Screen (Timeline Stepper):
- Full-screen dedicated view while job is active
- Timeline stepper with ONE-TAP advance buttons:

```
  ✓ Accepted          [auto — when they tapped accept]
  → En Route          [auto — set on accept]
  ○ Arrived           [tap "I've Arrived" button]
  ○ Work Started      [tap "Start Work" button]
  ○ Work Completed    [tap "Complete Job" button — requires confirmation dialog]
```

- Each step tap → Firestore update advancing timeline with timestamp (`arrived_at`, `started_at`, `completed_at`)
- Customer sees update in real-time

- **Photo capture** at key milestones:
  - "Arrived" → prompt to take photo of the problem (before photo)
  - "Completed" → prompt to take photo of finished work (after photo)
  - Photos stored as base64 in Firestore (hackathon) or Firebase Storage URLs (production)

- **Work timer**: auto-starts when "Work Started" tapped, shows elapsed time prominently. On completion, `actual_hours` calculated and stored.

- **"Add Extra Work" button**:
  - Worker describes additional work needed + estimated cost
  - Appends to `extra_work` array with `approved: false`
  - Customer gets real-time notification to approve/reject
  - Worker cannot mark job complete until all `extra_work` items have `approved: true`

- **SOS button**: calls platform support number (simulated)
- **In-app chat button**: opens chat with customer (Firestore sub-collection)

#### Job Completion:
- Worker taps "Complete Job" → confirmation dialog
- On confirm →
  1. Firestore: `status: "completed"`, `completed_at: Timestamp.now()`
  2. Calculate `final_price`: if `actual_hours` differs from `hours_estimated`, adjust `base` proportionally
  3. Create earning record in `/earnings/` collection
  4. Update worker's `total_jobs += 1` in `/providers/` document
  5. Trigger `recalculate_worker_performance()` via backend
  6. Customer gets rating prompt in their app
  7. Show earnings summary card: gross, platform fee, net payout

### 3.3 — Earnings & Payouts

#### Dashboard (Firestore queries):

```dart
// Today's earnings — real-time
db.collection('earnings')
  .where('worker_id', isEqualTo: myId)
  .where('created_at', isGreaterThan: todayStart)
  .snapshots()
```

- Today's earnings (real-time counter)
- This week / this month summary
- Earnings bar chart (last 30 days, using `fl_chart`)
- Pending vs cleared funds
- Average job value, jobs completed count (today / week / month / all-time)

#### Payout:
- Auto-payout simulation: daily at midnight, batch all `cleared` earnings → create payout record
- Transaction history with date filters
- Payout method management (edit JazzCash/EasyPaisa/bank in profile)

#### Incentives:
- Streak bonuses: 5 jobs in a day → PKR 500 bonus earning record
- Rating bonus: maintain 4.8+ for a week → 10% platform fee reduction on next 5 jobs
- Referral: invite another worker → PKR 1000 when they complete 5 jobs

### 3.4 — Schedule & Availability

#### Calendar View:
```dart
db.collection('bookings')
  .where('provider_id', isEqualTo: myId)
  .where('slot', isGreaterThan: weekStart)
  .where('slot', isLessThan: weekEnd)
  .get()
```
- Color-coded: confirmed (green), en_route/in_progress (blue), completed (gray), cancelled (red)
- Tap slot → navigate to job details
- Tap empty slot → block/unblock availability → Firestore update to `available_slots`
- Buffer time display: grayed-out 30-min blocks after each job

#### Smart Availability Hints:
- "Demand is high for electricians in DHA between 6-9 PM"
- "You have a 2.3km gap between your 2 PM and 4 PM jobs — consider adding buffer time"

### 3.5 — Ratings & Reviews

- Overall star average, star histogram (5/4/3/2/1 distribution)
- Individual reviews: customer name, rating, review text, date
- Worker can reply once per review → Firestore update `worker_reply` field

#### Performance Metrics (stored in provider document):
- On-time arrival rate, completion rate, cancellation rate, average response time
- **Show connection to ranking**: "Your on-time score of 95% contributes 20% to your discovery ranking"

### 3.6 — Notifications & Communication

#### Firestore-Driven Notifications:
- Real-time listener on `/notifications/` where `worker_id == me`
- `flutter_local_notifications` shows system notification when app is in background
- Notification types with distinct icons:
  - 🔧 New job (full-screen overlay, highest priority)
  - ✅ Booking confirmed by customer
  - ❌ Customer cancelled (with reason)
  - 💰 Payment received
  - ⭐ Rating received
  - ⏰ Upcoming job reminder (1 hour before)
  - 📊 Weekly earnings summary

#### In-App Chat (Firestore sub-collection):
- `/bookings/{ref}/messages/` — real-time listener
- Pre-built quick reply chips in Urdu:
  - "آ رہا ہوں" (On my way)
  - "پہنچ گیا" (I've arrived)
  - "کام شروع کر رہا ہوں" (Starting work)
  - "مکمل ہو گیا" (Done)
  - "سامان چاہیے" (Need materials)
  - "تھوڑا وقت لگے گا" (Will take some more time)
- System messages auto-inserted: "Worker is en route", "Worker has arrived", etc.
- Chat visible for 48 hours after job completion

### 3.7 — Offline Support (Firestore Handles This)

Firestore offline persistence is enabled by default in Flutter:
- All reads serve from local cache when offline
- All writes queue locally and sync when back online
- Job accept/decline/status updates work offline → auto-sync
- Earnings data cached and readable offline (with "last updated" shown)

Additional offline handling:
- GPS unavailable → allow manual zone selection; warn "Your ranking may be lower without GPS"
- Show "Offline" badge in app bar (`connectivity_plus`)
- Minimal data mode: skip loading photos, reduce sync frequency

---

## SECTION 4 — BACKEND EXTENSIONS (FastAPI + Firestore)

Add these endpoints to existing `/hizmat_ai/backend/main.py`. Do NOT break existing customer endpoints. All use `firebase-admin` SDK.

### 4.1 — Worker-Specific Endpoints

```python
# Auth
POST /worker/register              # Create Firestore provider document after Firebase Auth signup
GET  /worker/profile               # Read provider doc by Firebase UID from auth token
PUT  /worker/profile               # Update provider doc fields
PUT  /worker/availability          # Toggle is_available + update lat/lng

# Job Management
POST /worker/jobs/{ref}/accept     # Firestore transaction: status → en_route, set accepted_at
POST /worker/jobs/{ref}/decline    # Append to declined_by, re-run run_rank_agent(excluded_providers=...), reassign
PUT  /worker/jobs/{ref}/status     # Advance timeline step + set corresponding timestamp
POST /worker/jobs/{ref}/extra      # Add extra_work line item (pending customer approval)
GET  /worker/jobs/active           # Query bookings where provider_id=me AND status in [en_route, arrived, in_progress]
GET  /worker/jobs/history          # Paginated query on completed/cancelled bookings

# Earnings
GET  /worker/earnings/summary      # Aggregate earnings by day/week/month
GET  /worker/earnings/history      # Paginated earnings list

# Ratings
GET  /worker/ratings               # Query bookings where customer_rating != null for this worker
POST /worker/ratings/{ref}/reply   # Update worker_reply field on booking

# Chat
POST /worker/chat/{ref}/send       # Add message to bookings/{ref}/messages sub-collection
GET  /worker/chat/{ref}/history    # Read messages sub-collection

# Performance
GET  /worker/performance           # Read on_time_score, cancellation_rate, etc. from provider doc
```

### 4.2 — Auth Middleware

```python
from firebase_admin import auth

async def verify_worker_token(request: Request):
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    decoded = auth.verify_id_token(token)
    request.state.uid = decoded["uid"]
    return decoded
```

Apply to all `/worker/` endpoints.

### 4.3 — Job Re-Assignment Logic (on decline)

Uses the **existing** `excluded_providers` parameter of `run_rank_agent()` — no signature change required:

```python
@app.post("/worker/jobs/{ref}/decline")
async def decline_job(ref: str, reason: str, request: Request):
    booking_doc = db.collection("bookings").document(ref)
    booking = booking_doc.get().to_dict()

    # Record this worker's decline
    booking_doc.update({
        "declined_by": firestore.ArrayUnion([{
            "provider_id": request.state.uid,
            "reason": reason,
            "at": firestore.SERVER_TIMESTAMP
        }]),
        "assignment_attempts": firestore.Increment(1)
    })

    # Collect all previously declined provider IDs
    declined_ids = [d["provider_id"] for d in booking.get("declined_by", [])]
    declined_ids.append(request.state.uid)

    # Re-run RankAgent — excluded_providers already exists in the function signature
    all_providers = [p.to_dict() for p in db.collection("providers").get()]
    ranked = run_rank_agent(
        providers=all_providers,
        user_lat=booking["customer_lat"],
        user_lng=booking["customer_lng"],
        service_type=booking["service_type"],
        excluded_providers=declined_ids          # ← existing parameter, no change needed
    )

    if ranked.get("ranked"):
        next_provider = ranked["ranked"][0]
        booking_doc.update({
            "provider_id": next_provider["id"],
            "provider_name": next_provider["name"],
            "status": "pending_worker"
        })
        # New worker's Firestore listener auto-detects this → shows notification
    else:
        booking_doc.update({"status": "no_provider_available"})
```

### 4.4 — Performance Recalculation (on job completion)

```python
def recalculate_worker_performance(worker_id: str):
    bookings = db.collection("bookings") \
        .where("provider_id", "==", worker_id) \
        .where("status", "in", ["completed", "cancelled"]) \
        .get()

    total = len(bookings)
    completed = sum(1 for b in bookings if b.to_dict()["status"] == "completed")
    on_time = sum(1 for b in bookings if was_on_time(b.to_dict()))
    cancelled = total - completed
    ratings = [b.to_dict()["customer_rating"] for b in bookings
               if b.to_dict().get("customer_rating")]

    db.collection("providers").document(worker_id).update({
        "total_jobs": completed,
        "completion_rate": completed / max(total, 1),
        "cancellation_rate": cancelled / max(total, 1),
        "on_time_score": on_time / max(completed, 1),
        "rating": sum(ratings) / max(len(ratings), 1),
        "review_count": len(ratings)
    })
    # These updated values are immediately used by RankAgent on next booking
```

### 4.5 — Integration with Existing Agent Pipeline

The 6 agents continue to work exactly as before, but read from Firestore instead of in-memory structures. Both `agents.py` and `adk_orchestrator.py` need this migration:

| Agent | What Changes |
|---|---|
| IntentAgent | Nothing — pure text parsing, no data dependency |
| DiscoveryAgent | Read from `db.collection("providers")` instead of `providers.json` |
| RankAgent | Same formula; `excluded_providers` param already exists — no signature change |
| PriceAgent | `hourly_rate` from Firestore (worker can update anytime); output shape unchanged |
| BookingAgent | Write to `db.collection("bookings")` instead of `_bookings_db.append()`; append `platform_fee` + `tax_gst` to breakdown before write |
| FollowupAgent | Read/update bookings from Firestore |
| adk_orchestrator.py | Replace `_sessions[sid]` dict with `db.collection("sessions").document(sid)` reads/writes |

**`agentEngine.js` (React web app)**: After Firestore migration, update `PROVIDERS_DB` field names to match Firestore schema (`pricePerHr` → `hourly_rate`, `completionRate` → `completion_rate`, `responseTime` → `avg_response_seconds`, `certified: bool` → `certifications: []`, `area` → `zone`).

---

## SECTION 5 — FLUTTER ARCHITECTURE SPEC

### 5.1 — Project Structure

```
hizmat_ai/flutter_worker_app/
├── lib/
│   ├── main.dart                           ← Firebase.initializeApp() + ProviderScope
│   ├── app.dart                            ← GoRouter + auth guard (redirect to /login if not signed in)
│   ├── core/
│   │   ├── constants.dart                  ← API base URL, timeouts, sample data
│   │   ├── theme.dart                      ← REUSE customer theme + worker accent (#FF6B35 orange)
│   │   └── extensions.dart                 ← BuildContext helpers
│   ├── models/
│   │   ├── worker_profile.dart             ← WorkerProfile model (maps to Firestore /providers/ doc)
│   │   ├── job.dart                        ← Job, JobStatus enum
│   │   ├── earning.dart                    ← Earning model
│   │   ├── review.dart                     ← Review model
│   │   └── chat_message.dart               ← ChatMessage model
│   ├── services/
│   │   ├── auth_service.dart               ← FirebaseAuth wrapper: phone sign-in, OTP verify, sign out
│   │   ├── firestore_service.dart          ← All Firestore CRUD: providers, bookings, earnings, messages
│   │   ├── location_service.dart           ← Geolocator GPS tracking, Haversine ETA
│   │   └── notification_service.dart       ← Flutter local notifications from Firestore listener events
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart           ← Phone input + "Send OTP" button
│   │   │   ├── otp_screen.dart             ← 6-digit OTP input + auto-verify
│   │   │   └── register_screen.dart        ← Multi-step profile setup (8 steps)
│   │   ├── home/
│   │   │   ├── worker_home_screen.dart     ← Online/offline toggle, active job card, today's stats
│   │   │   └── widgets/
│   │   │       ├── availability_toggle.dart ← Big prominent switch
│   │   │       ├── stats_card.dart          ← Today: jobs, earnings, rating
│   │   │       └── incoming_job_overlay.dart ← Full-screen job offer with countdown
│   │   ├── jobs/
│   │   │   ├── active_job_screen.dart       ← Timeline stepper, photo capture, timer, chat
│   │   │   ├── job_details_screen.dart      ← Read-only job detail view
│   │   │   ├── job_history_screen.dart      ← Filterable list of past jobs
│   │   │   └── widgets/
│   │   │       ├── timeline_stepper.dart    ← Visual stepper with one-tap advance
│   │   │       ├── photo_capture.dart       ← Camera/gallery picker
│   │   │       └── extra_work_sheet.dart    ← Bottom sheet for adding extra work
│   │   ├── earnings/
│   │   │   ├── earnings_screen.dart         ← Dashboard + fl_chart bar chart
│   │   │   └── transaction_history.dart     ← Scrollable list with date filters
│   │   ├── schedule/
│   │   │   └── calendar_screen.dart         ← Weekly grid, tap to block/unblock
│   │   ├── ratings/
│   │   │   └── ratings_screen.dart          ← Star histogram + reviews + reply button
│   │   ├── chat/
│   │   │   └── chat_screen.dart             ← Real-time Firestore chat, quick replies
│   │   └── profile/
│   │       └── worker_profile_screen.dart   ← Edit all fields, payout settings
│   └── providers/                           ← Riverpod providers
│       ├── auth_provider.dart               ← StreamProvider<User?> from FirebaseAuth
│       ├── job_provider.dart                ← StreamProvider from Firestore bookings listener
│       ├── earnings_provider.dart           ← FutureProvider for earnings queries
│       ├── profile_provider.dart            ← StreamProvider for own provider doc
│       └── location_provider.dart           ← StateNotifierProvider for GPS state
```

### 5.2 — State Management (Riverpod + Firestore Streams)

```dart
// Auth state
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Worker's own profile — real-time
final workerProfileProvider = StreamProvider<WorkerProfile>((ref) {
  final uid = ref.watch(authProvider).value?.uid;
  if (uid == null) throw Exception('Not authenticated');
  return FirebaseFirestore.instance
    .collection('providers')
    .doc(uid)
    .snapshots()
    .map((snap) => WorkerProfile.fromFirestore(snap));
});

// Incoming jobs — real-time
final incomingJobsProvider = StreamProvider<List<Job>>((ref) {
  final uid = ref.watch(authProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
    .collection('bookings')
    .where('provider_id', isEqualTo: uid)
    .where('status', isEqualTo: 'pending_worker')
    .snapshots()
    .map((snap) => snap.docs.map((d) => Job.fromFirestore(d)).toList());
});

// Active job — real-time
final activeJobProvider = StreamProvider<Job?>((ref) {
  final uid = ref.watch(authProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
    .collection('bookings')
    .where('provider_id', isEqualTo: uid)
    .where('status', whereIn: ['en_route', 'arrived', 'in_progress'])
    .limit(1)
    .snapshots()
    .map((snap) => snap.docs.isEmpty ? null : Job.fromFirestore(snap.docs.first));
});

// Today's earnings — real-time
final todayEarningsProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authProvider).value?.uid;
  final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
  return FirebaseFirestore.instance
    .collection('earnings')
    .where('worker_id', isEqualTo: uid)
    .where('created_at', isGreaterThan: Timestamp.fromDate(todayStart))
    .snapshots()
    .map((snap) => snap.docs.fold(0, (sum, d) => sum + (d['net_amount'] as int)));
});
```

### 5.3 — Navigation (GoRouter with Auth Guard)

```dart
final router = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                        state.matchedLocation.startsWith('/register') ||
                        state.matchedLocation.startsWith('/otp');
    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/otp', builder: (_, state) => OtpScreen(verificationId: state.extra as String)),
    ShellRoute(
      builder: (_, __, child) => WorkerShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const WorkerHomeScreen()),
        GoRoute(path: '/jobs', builder: (_, __) => const JobHistoryScreen()),
        GoRoute(path: '/earnings', builder: (_, __) => const EarningsScreen()),
        GoRoute(path: '/schedule', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const WorkerProfileScreen()),
      ],
    ),
    GoRoute(path: '/job/:ref', builder: (_, state) => ActiveJobScreen(ref: state.pathParameters['ref']!)),
    GoRoute(path: '/job/:ref/chat', builder: (_, state) => ChatScreen(ref: state.pathParameters['ref']!)),
    GoRoute(path: '/ratings', builder: (_, __) => const RatingsScreen()),
  ],
);
```

### 5.4 — Design System (Worker-Specific Extensions)

```dart
class WorkerColors {
  // Worker accent — warm orange (customer app uses mint #00B894 + purple #6C5CE7)
  static const accent = Color(0xFFFF6B35);
  static const accentLight = Color(0xFFFFF3ED);

  // Status
  static const online = Color(0xFF00B894);      // mint = available
  static const offline = Color(0xFFFF5252);     // red = offline
  static const onJob = Color(0xFF0284C7);       // blue = working

  // Job urgency
  static const urgent = Color(0xFFFF5252);
  static const normal = Color(0xFF0284C7);

  // Earnings
  static const moneyGreen = Color(0xFF059669);

  // Shared with customer theme — import from customer theme, do not redefine:
  // background: 0xFFF6F7FB, surface: 0xFFFFFFFF, text: 0xFF1A1D26, textMuted: 0xFF7C8DB0
}

class WorkerSizes {
  static const minTouchTarget = 52.0;    // larger than customer (44dp) for outdoor/gloved use
  static const bodyFontSize = 16.0;      // 10% larger than customer app
  static const headingFontSize = 22.0;
  static const cardRadius = 20.0;
  static const buttonHeight = 56.0;
}
```

### 5.5 — Dependencies (`pubspec.yaml`)

```yaml
name: hizmat_worker
description: HizmatAI Worker App

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Firebase — same project as customer app (hizmatai)
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0

  # State + Navigation — match customer app exactly
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0

  # UI
  google_fonts: ^6.1.0
  flutter_animate: ^4.5.0
  fl_chart: ^0.70.0

  # Device
  geolocator: ^12.0.0
  image_picker: ^1.0.7
  connectivity_plus: ^6.0.3
  flutter_local_notifications: ^18.0.0
  local_auth: ^2.2.0

  # Utilities
  uuid: ^4.3.3
  intl: ^0.19.0
  url_launcher: ^6.2.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

---

## SECTION 6 — CRITICAL EDGE CASES & FAILURE MODES

Handle every one of these:

### 6.1 — Race Conditions
- **Two workers see the same job**: Firestore `runTransaction()` — check `status == "pending_worker"` before setting `en_route`. Second worker gets "Job taken" overlay.
- **Customer cancels while worker is en route**: Worker's Firestore listener fires immediately → full-screen "Customer Cancelled" overlay with cancellation fee notice.
- **Worker accepts but goes offline**: If `status == "en_route"` and `last_location_update` > 5 min old, backend auto-reassigns using `run_rank_agent(excluded_providers=[...])`.

### 6.2 — GPS & Location
- **GPS off**: Allow manual zone selection, warn "Your ranking may be lower without GPS"
- **GPS spoofing**: Server-side validate in `/worker/availability`: if Haversine(new_location, last_known) > 50km and time_diff < 10 min, reject + flag account
- **City boundary crossing during job**: Price locked at booking time. No mid-job repricing.

### 6.3 — Payment Edge Cases
- **Job completed but customer disputes**: Set earning `status: "disputed"`, show "Under Review"
- **Customer payment fails after completion**: Worker still paid — create earning record regardless
- **Extra work pricing**: All `extra_work` items require `approved: true` before job can be marked complete

### 6.4 — Connectivity
- **Accept job while offline**: Firestore queues write locally. Warn: "You're offline — acceptance will confirm when reconnected"
- **Complete job offline**: Timeline timestamps use device time, sync on reconnect
- **App crash mid-job**: `activeJobProvider` reads from Firestore cache on restart → resumes exactly where left off

### 6.5 — Booking Lifecycle Conflicts
- **Worker marks "Arrived" but customer not home**: "Customer Not Home" button → 15-min wait timer → auto-cancel with `no_show` reason + customer no-show fee
- **Can't complete job (wrong parts)**: "Partial Completion" flow → log actual work done + photos → charge proportionally on `actual_hours`
- **Overlapping jobs**: On accept, check: does worker have another booking in `[en_route, arrived, in_progress]`? If yes, reject with "Complete your current job first."

### 6.6 — Cultural / Market Context (Pakistan-Specific)
- **Shared phones**: Earnings screen re-authenticates via `local_auth`
- **Low literacy**: Large icons + color coding + visual timeline stepper. Minimize text. Urdu quick-reply chips.
- **Load shedding**: Firestore offline cache means app works during power outages. Restarts resume from cached state.
- **Data costs**: Offline persistence default. Listeners > repeated fetches. Photos compressed < 500KB before write.
- **APK size target**: < 30 MB (Firebase adds ~8MB over base Flutter)

---

## SECTION 7 — QUALITY GATES & VALIDATION CHECKLIST

### Architecture
- [ ] Worker app is a SEPARATE Flutter project (`hizmat_ai/flutter_worker_app/`)
- [ ] Firebase initialized in `main.dart` with `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
- [ ] `firebase_options.dart` copied from customer app (same Firebase project: `hizmatai`)
- [ ] All Firestore reads/writes go through `firestore_service.dart`
- [ ] GoRouter auth guard redirects to `/login` when not authenticated
- [ ] Backend `/worker/` endpoints verify Firebase ID token via `auth.verify_id_token()`
- [ ] No breaking changes to existing customer endpoints or agent pipeline
- [ ] `providers.json` data seeded into Firestore `providers` collection via `seed_firestore.py`
- [ ] `firestore.rules` and `firestore.indexes.json` updated by merging, not replacing

### Data Integrity
- [ ] Booking status transitions enforced: `pending_worker → en_route → arrived → in_progress → completed` (no backward transitions)
- [ ] Firestore transaction used for job acceptance (prevents double-accept race condition)
- [ ] `platform_fee` (PKR 99) and `tax_gst` (5%) appended by BookingAgent before Firestore write — NOT by PriceAgent
- [ ] Worker's `is_available` toggle immediately reflected in DiscoveryAgent Firestore queries
- [ ] Worker's `hourly_rate` changes reflected in next PriceAgent calculation
- [ ] Performance metrics (`on_time_score`, `cancellation_rate`) recalculated after every job completion
- [ ] Decline re-assignment uses existing `excluded_providers` parameter of `run_rank_agent()` — no signature change needed
- [ ] All `extra_work` items require `approved: true` before final price calculation

### Real-Time Sync
- [ ] Customer sees worker status change within 1 second (Firestore listener)
- [ ] Worker sees incoming job within 1 second of booking creation
- [ ] Chat messages appear instantly on both sides
- [ ] Earnings dashboard updates in real-time as jobs complete
- [ ] Online/offline toggle reflects immediately in DiscoveryAgent provider filter

### UX
- [ ] Incoming job notification is full-screen overlay with sound + vibration
- [ ] Online/offline toggle is the most prominent element on home screen (minimum 52dp)
- [ ] Active job screen requires exactly 1 tap to advance each timeline step
- [ ] All screens work offline (Firestore cache) with "Offline" indicator
- [ ] Urdu quick-reply chips render correctly (RTL where needed)
- [ ] Font sizes: minimum 16sp body text (outdoor readability)
- [ ] Touch targets: minimum 52dp for all actionable elements
- [ ] Photo capture prompts at "Arrived" and "Completed" steps

### Performance
- [ ] App cold start < 3 seconds (Firebase init + Firestore cache read)
- [ ] Job accept round-trip < 500ms (Firestore transaction + listener fire)
- [ ] GPS polling: 30s when active job, 5 min when idle
- [ ] Photos compressed to < 500KB before Firestore write
- [ ] APK size < 30 MB

### Security
- [ ] Firebase Auth token required on all `/worker/` backend endpoints
- [ ] Firestore security rules enforce: worker can only read/write own data
- [ ] CNIC stored with restricted read access (worker only, not queryable)
- [ ] Customer exact address only visible after worker accepts (status != `pending_worker`)
- [ ] Worker phone number never exposed to customer — use in-app Firestore chat
- [ ] Biometric/PIN lock on earnings screen via `local_auth`

### Integration
- [ ] Worker accept → customer's Firestore listener fires → shows "Provider assigned" + ETA
- [ ] Worker timeline advance → customer timeline updates in real-time
- [ ] Worker decline → backend re-runs `run_rank_agent(excluded_providers=[...])` → assigns next provider → new worker's listener fires
- [ ] Worker completes job → customer gets rating prompt
- [ ] Worker's updated `hourly_rate` used by PriceAgent on next booking
- [ ] Worker's `on_time_score` / `cancellation_rate` feed into RankAgent 6-factor scoring
- [ ] `agentEngine.js` PROVIDERS_DB field names updated to match Firestore schema after migration

---

## SECTION 8 — IMPLEMENTATION PRIORITY ORDER

Build in this exact order. Each phase is independently demoable:

### Phase 1 — CORE LOOP (MVP for demo)
1. Copy `firebase_options.dart` from customer app into worker app; add `google-services.json` to `android/app/`
2. Phone authentication (login + OTP verification)
3. Worker registration (multi-step profile → Firestore `/providers/` doc)
4. Run `seed_firestore.py` to migrate `providers.json` into Firestore (slots auto-refreshed to future dates)
5. Online/offline toggle with GPS location update
6. Incoming job real-time listener + full-screen overlay notification
7. Job accept with Firestore transaction (race condition guard)
8. Job decline → backend re-assignment via `excluded_providers`
9. Active job timeline stepper (en_route → arrived → completed)
10. Basic earnings display (today's total from Firestore)
11. **Backend**: add `firebase-admin` to `requirements.txt`, initialize in `main.py`
12. **Backend**: migrate `agents.py` — swap `providers.json` load → Firestore query; `_bookings_db` → Firestore writes; append `platform_fee` + `tax_gst` in BookingAgent
13. **Backend**: migrate `adk_orchestrator.py` — swap `_sessions` dict → Firestore `sessions` collection
14. **Backend**: add `/worker/` endpoints with Firebase Auth middleware

### Phase 2 — FULL LIFECYCLE
15. Job history screen with date/status filters
16. Earnings dashboard + `fl_chart` bar chart (30-day view)
17. Schedule/calendar view from Firestore bookings
18. Photo capture at milestones (before/after)
19. In-app chat (Firestore sub-collection + quick Urdu replies)
20. Performance metrics calculation + display
21. **Customer app update**: add Firestore listeners for real-time worker status in existing `/hizmat_ai/flutter_app/`
22. Decline → re-assignment logic fully wired end-to-end

### Phase 3 — POLISH
23. Ratings & reviews screen with worker reply
24. Extra work flow (add items → customer approval → price adjustment)
25. Profile management (edit rate, zones, specializations, payout method)
26. Notification history screen
27. Biometric lock on sensitive screens
28. Urdu language support for key UI elements
29. Smart availability hints (demand patterns)
30. Incentive badges (streak bonus, rating bonus)
31. **React web app**: update `agentEngine.js` PROVIDERS_DB field names to match Firestore schema

---

## SECTION 9 — FIREBASE SETUP (EXISTING PROJECT)

```bash
# Firebase project already exists as 'hizmatai' — do NOT create a new one

# 1. Install FlutterFire CLI (if not already installed)
dart pub global activate flutterfire_cli

# 2. Configure worker Flutter app against the EXISTING project
cd hizmat_ai/flutter_worker_app
flutterfire configure --project=hizmatai
# This generates firebase_options.dart — alternatively copy from flutter_app/lib/firebase_options.dart

# 3. Firestore and Phone Auth are already enabled in project hizmatai
# Verify at: console.firebase.google.com → project hizmatai

# 4. Download service account key for backend (if not already done)
# Firebase Console → Project Settings → Service accounts → Generate new private key
# Save as hizmat_ai/backend/serviceAccountKey.json

# 5. Verify .gitignore entries exist (check /Users/admin/Desktop/aihack/.gitignore)
echo "serviceAccountKey.json" >> .gitignore
echo "google-services.json" >> .gitignore

# 6. Seed providers into Firestore
cd hizmat_ai/backend
python seed_firestore.py

# 7. Run the worker app
cd hizmat_ai/flutter_worker_app
flutter run -d chrome    # web
flutter build apk        # Android APK
```

### Firestore Indexes (MERGE into existing `/firestore.indexes.json`)

```json
{
  "indexes": [
    {"collectionGroup": "bookings",      "fields": [{"fieldPath": "provider_id", "order": "ASCENDING"}, {"fieldPath": "status", "order": "ASCENDING"}, {"fieldPath": "slot", "order": "DESCENDING"}]},
    {"collectionGroup": "bookings",      "fields": [{"fieldPath": "provider_id", "order": "ASCENDING"}, {"fieldPath": "created_at", "order": "DESCENDING"}]},
    {"collectionGroup": "earnings",      "fields": [{"fieldPath": "worker_id", "order": "ASCENDING"}, {"fieldPath": "created_at", "order": "DESCENDING"}]},
    {"collectionGroup": "notifications", "fields": [{"fieldPath": "worker_id", "order": "ASCENDING"}, {"fieldPath": "created_at", "order": "DESCENDING"}]},
    {"collectionGroup": "providers",     "fields": [{"fieldPath": "service_type", "order": "ASCENDING"}, {"fieldPath": "is_available", "order": "ASCENDING"}, {"fieldPath": "city", "order": "ASCENDING"}]}
  ]
}
```

---

## SECTION 10 — CONSTRAINTS

- Firebase free tier (Spark plan) — no credit card required; project `hizmatai` already active
- Stripe test mode only for payments (match existing pattern in `main.py`)
- GPS via `geolocator` package, distance via Haversine (no Google Maps SDK)
- Target: Flutter Android APK + Web. iOS not required.
- Match existing code style: functional Riverpod providers, GoRouter, feature-based directories
- Maintain same design language (light morphism, soft shadows, rounded corners) with worker orange accent (#FF6B35) to visually differentiate from customer mint-green (#00B894)
- Backend changes must be backward-compatible — all existing customer endpoints and agent logic continue working
- `run_rank_agent()` and `run_price_agent()` function signatures must NOT change — only add Firestore I/O around them
- The 6-agent pipeline (IntentAgent → DiscoveryAgent → RankAgent → PriceAgent → BookingAgent → FollowupAgent) remains the core intelligence — worker app is the execution layer that feeds real performance data back into it
