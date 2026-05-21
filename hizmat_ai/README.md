# HizmatAI — Agentic Home Service Orchestrator for Pakistan's Informal Economy

> **Challenge 2: AI Service Orchestrator for Informal Economy**
> 3-day hackathon submission | Google ADK (Antigravity) + Gemini 2.5 Flash

HizmatAI is a fully agentic system that matches Pakistani users with home service providers through natural conversation in **Urdu, Roman Urdu, and English**. Google ADK's Gemini orchestrator autonomously decides which agents to invoke, in what order, and generates human-readable reasoning at each step.

---

## Architecture: Google ADK Orchestration

```
User Input (Urdu / Roman Urdu / English)
      |
      v
 +---------------------------+
 | Google ADK Orchestrator   |  <-- Gemini 2.5 Flash decides the pipeline
 | (Antigravity LlmAgent)    |
 +---------------------------+
      |  Autonomous tool calls
      v
 +-----------+     +----------------+     +-----------+
 | Intent    | --> | Discovery      | --> | Rank      |
 | Agent     |     | Agent          |     | Agent     |
 | (NLP/NER) |     | (zone search)  |     | (scoring) |
 +-----------+     +----------------+     +-----------+
      |                                        |
      v                                        v
 +-----------+     +----------------+     +-----------+
 | Price     | --> | Booking        | --> | Followup  |
 | Agent     |     | Agent          |     | Agent     |
 | (dynamic) |     | (conflict chk) |     | (remind)  |
 +-----------+     +----------------+     +-----------+
```

**Key:** Gemini orchestrates ALL agent workflows. Each tool function wraps a specialized agent. The LLM decides when and how to call each based on the user's natural language input.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Orchestrator** | Google ADK v2.0 (`LlmAgent`, `Runner`, `InMemorySessionService`) |
| **LLM** | Gemini 2.5 Flash (paid tier) |
| **Backend** | Python FastAPI, async, CORS-enabled |
| **Frontend** | Flutter 3.22 (Web + Android), Riverpod, GoRouter |
| **Distance** | Haversine formula (zero-cost, no Maps SDK) |
| **Design** | Light morphism (Awwwards-inspired), Poppins typography |

---

## 6-Agent Pipeline

| # | Agent | Function | What It Does |
|---|-------|----------|-------------|
| 1 | **IntentAgent** | `parse_intent()` | NLP on Urdu/Roman Urdu/English; extracts service type, zone, urgency |
| 2 | **DiscoveryAgent** | `discover_providers()` | Searches provider dataset by service type + zone with fallback |
| 3 | **RankAgent** | `rank_providers()` | Weighted scoring: distance 20%, rating 25%, reliability 20%, specialization 15%, price 10%, cancellation 10% |
| 4 | **PriceAgent** | `calculate_price()` | Dynamic PKR pricing: base + urgency + distance + surge - loyalty |
| 5 | **BookingAgent** | `create_booking()` | Slot confirmation with double-booking conflict detection |
| 6 | **FollowupAgent** | `schedule_followup()` | Reminders, status updates, cancellation handling, disputes |

---

## Demo Scenarios (For Judges)

Built-in scenario buttons on the home screen demonstrate edge cases:

| Scenario | Input | What Happens |
|----------|-------|-------------|
| **A: Double Booking** | "Mujhe DHA Phase 2 mein AC repair chahiye abhi" | BookingAgent detects slot conflict, suggests next available |
| **B: No Zone Match** | "G-13 Islamabad mein AC technician chahiye" | DiscoveryAgent falls back to cross-zone search |
| **C: Ambiguous Input** | "koi repair wala chahiye ghar mein" | IntentAgent asks clarification (which service type?) |
| **D: Full Pipeline** | "Electrician chahiye DHA mein, urgent hai" | All 6 agents execute end-to-end with booking confirmation |

Also available via API: `POST /scenario {"scenario": "A"}`

---

## Agent Trace Panel

Every interaction produces a complete agent trace visible in-app:
- Tap the **trace button** (top-right) to see all steps
- Each step shows: agent name, action, reasoning, timestamp
- Color-coded by agent type (7 distinct colors)
- Collapsible detail view with full reasoning text
- "Powered by Google ADK (Antigravity)" banner with step + tool counters

---

## Quick Start

### Backend
```bash
cd backend
pip install -r requirements.txt
# Set your Gemini API key
echo "GOOGLE_API_KEY=your_key_here" > .env
uvicorn main:app --reload --port 8000
```

### Flutter App
```bash
cd flutter_app
flutter pub get
flutter run -d chrome --web-port=8080
```

### Verify
```bash
curl http://localhost:8000/health
# → {"status":"healthy","model":"gemini-2.5-flash (Google ADK orchestrated)","version":"2.0.0"}
```

---

## API Endpoints

| Method | Route | Purpose |
|--------|-------|---------|
| `POST` | `/chat` | **Main endpoint** — ADK orchestrated full pipeline |
| `POST` | `/intent` | Direct IntentAgent call |
| `POST` | `/rank` | Direct RankAgent call |
| `POST` | `/price` | Direct PriceAgent call |
| `POST` | `/book` | Direct BookingAgent call |
| `POST` | `/followup` | Direct FollowupAgent call |
| `POST` | `/scenario` | Trigger demo scenarios A/B/C/D |
| `GET` | `/trace` | Full session agent trace |
| `GET` | `/health` | Status + model info |

---

## Provider Dataset

25 providers across 6 service categories in 10 zones:
- **Services:** AC Repair, Plumber, Electrician, Cleaner, Beautician, Home Tutor
- **Cities:** Karachi, Lahore, Islamabad
- **Zones:** DHA Phase 2, Gulshan-e-Iqbal, G-13, Nazimabad, Clifton, PECHS, North Nazimabad, Bahria Town, Johar, Saddar

---

## Competition Rubric Alignment

| Criteria (Weight) | How We Address It |
|-------------------|-------------------|
| **Antigravity (25%)** | Google ADK `LlmAgent` + `Runner` as core orchestrator; Gemini 2.5 Flash LLM; all agent calls are ADK tool functions |
| **Agentic Reasoning (20%)** | 6-agent pipeline with autonomous tool selection; Gemini decides workflow order; ambiguity detection + clarification; visible reasoning trace |
| **Matching Quality (20%)** | 6-factor weighted scoring; zone fallback; dynamic pricing with 5 fee components |
| **Action Simulation (15%)** | Real booking with conflict detection; 4 demo scenarios covering edge cases; WhatsApp reminder simulation |
| **Technical Implementation (10%)** | Async FastAPI; retry with backoff; Flutter Riverpod state; graceful mock fallback |
| **Innovation & UX (10%)** | Trilingual NLP (Urdu/Roman Urdu/English); light morphism Awwwards design; agent trace transparency |

---

## Design System

| Token | Value |
|-------|-------|
| Background | `#F6F7FB` (warm off-white) |
| Surface | `#FFFFFF` (pure white cards) |
| Primary | `#00B894` (mint green) |
| Accent | `#6C5CE7` (purple, agent trace) |
| Font | Poppins (Google Fonts) |
| Shadows | Multi-layer soft shadows (light morphism) |
| Touch targets | 44x44dp minimum |

---

Built by **Syed Ahnaf Raza** | Bahria University Karachi
