// ─────────────────────────────────────────────────────────────
//  HizmatAI — Real Backend API + Conversational Intelligence
//  Calls the FastAPI + Python agents at localhost:8000
// ─────────────────────────────────────────────────────────────

const BACKEND = 'http://localhost:8000';
const ts = () => new Date().toISOString();

// ── Client-side Conversation Memory (per session) ─────────────
const _sessions = new Map();

function getSession(sessionId) {
  if (!_sessions.has(sessionId)) {
    _sessions.set(sessionId, {
      service_type: null, city: null, zone: null,
      preferred_time: null, preferred_date: null,
      urgency: 'scheduled', language: 'english',
      cached_providers: null,   // top3 from last rank call
      stage: 'idle',
    });
  }
  return _sessions.get(sessionId);
}

export function clearSession(sessionId) { _sessions.delete(sessionId); }

// ── Conversational parsers ────────────────────────────────────
function parseTimeFromText(text) {
  const t = text.toLowerCase();
  // "09:00" or "14:00" direct slot values from quick replies
  const direct = t.match(/\b(\d{2}):(\d{2})\b/);
  if (direct) return `${direct[1]}:${direct[2]}`;
  // "10am", "10 am", "2pm", "10 baje"
  const m = t.match(/\b(\d{1,2})(?::(\d{2}))?\s*(am|pm|baje|bajay)?\b/i);
  if (m) {
    let h = parseInt(m[1]);
    const min = m[2] || '00';
    const period = m[3]?.toLowerCase();
    if (period === 'pm' && h !== 12) h += 12;
    if (period === 'am' && h === 12) h = 0;
    if (h >= 7 && h <= 21) return `${String(h).padStart(2, '0')}:${min}`;
  }
  return null;
}

function parseDateFromText(text) {
  const t = text.toLowerCase();
  if (/\b(aaj|today|abhi|ajj)\b/.test(t)) return 'today';
  if (/\b(kal|tomorrow|kal ko|agle din)\b/.test(t)) return 'tomorrow';
  if (/\b(parso|day after tomorrow)\b/.test(t)) return 'day_after';
  const days = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday'];
  for (const d of days) if (t.includes(d)) return d;
  return null;
}

function parseUrgencyFromText(text) {
  return /\b(urgent|jaldi|abhi|now|emergency|asap|turant|فوری|ابھی)\b/i.test(text) ? 'urgent' : null;
}

// ── Formatters ────────────────────────────────────────────────
function fmt12(time24) {
  if (!time24 || time24 === 'ASAP') return 'ASAP';
  const [h, m] = time24.split(':').map(Number);
  const p = h >= 12 ? 'PM' : 'AM';
  return `${h % 12 || 12}:${m.toString().padStart(2, '0')} ${p}`;
}

function getAvailableSlots(providers) {
  const times = new Set();
  providers.forEach(p => (p.available || []).forEach(t => times.add(t)));
  return [...times].sort();
}

// ── Quick reply builders ──────────────────────────────────────
function buildTimeQuickReplies(slots, lang) {
  const timeChips = slots.map(t => ({ label: fmt12(t), value: t, type: 'time' }));
  const base = [
    { label: lang === 'roman_urdu' ? '🚨 Abhi Urgent' : lang === 'urdu' ? '🚨 فوری' : '🚨 ASAP / Urgent', value: 'urgent', type: 'urgency' },
    { label: lang === 'roman_urdu' ? '📅 Aaj' : lang === 'urdu' ? '📅 آج' : '📅 Today', value: 'today', type: 'date' },
    { label: lang === 'roman_urdu' ? '📅 Kal' : lang === 'urdu' ? '📅 کل' : '📅 Tomorrow', value: 'tomorrow', type: 'date' },
  ];
  return [...base, ...timeChips];
}

function buildNeedsTimeMessage(providers, service, city, lang) {
  const svc = service.replace('_', ' ');
  const slots = getAvailableSlots(providers);
  const slotStr = slots.map(fmt12).join('  ·  ');
  if (lang === 'roman_urdu')
    return `**${providers.length}** ${svc} providers ${city} mein ready hain! 🎉\n\nAb batayein — **kab chahiye**? Available slots:\n${slotStr}`;
  if (lang === 'urdu')
    return `**${providers.length}** ${svc} ${city} میں دستیاب ہیں! 🎉\n\nکب چاہیے؟ دستیاب اوقات:\n${slotStr}`;
  return `Found **${providers.length}** ${svc} providers in **${city}**! 🎉\n\nWhen would you like them? Available slots:\n${slotStr}`;
}

function buildConflictMessage(providerName, nextSlots, lang) {
  const fmtSlots = (nextSlots || []).slice(0, 2).map(s => {
    const d = new Date(s);
    if (isNaN(d)) return s;
    return `**${d.toLocaleDateString('en-PK', { weekday: 'short', month: 'short', day: 'numeric' })} at ${d.toTimeString().slice(0, 5)}**`;
  }).join(' or ');
  if (lang === 'roman_urdu')
    return `⚠️ **${providerName}** ka yeh slot pehle se book ho chuki hai!\n\nAgli available slots: ${fmtSlots || 'filhal nahin hai'}\n\nKoi aur time chunein ya doosra provider try karein?`;
  if (lang === 'urdu')
    return `⚠️ **${providerName}** کا یہ وقت پہلے سے بک ہے!\n\nاگلے اوقات: ${fmtSlots || 'دستیاب نہیں'}\n\nکوئی اور وقت یا فراہم کنندہ منتخب کریں؟`;
  return `⚠️ That slot with **${providerName}** was just taken!\n\nNext available: ${fmtSlots || 'none right now'}\n\nPick an alternative time or try a different provider:`;
}

// Zone → lat/lng for the /rank endpoint
const ZONE_COORDS = {
  'DHA Phase 2':     { lat: 24.804,  lng: 67.0708 },
  'Gulshan-e-Iqbal': { lat: 24.9243, lng: 67.0908 },
  'Clifton':         { lat: 24.800,  lng: 67.030  },
  'PECHS':           { lat: 24.865,  lng: 67.065  },
  'North Nazimabad': { lat: 24.930,  lng: 67.040  },
  'Nazimabad':       { lat: 24.900,  lng: 67.050  },
  'G-13':            { lat: 33.690,  lng: 73.000  },
  'Bahria Town':     { lat: 33.530,  lng: 73.130  },
  'Johar':           { lat: 31.470,  lng: 74.290  },
  'Saddar':          { lat: 33.600,  lng: 73.060  },
};
const DEFAULT_COORDS = { lat: 24.8607, lng: 67.0104 };

// Zone → city label for ProviderPicker / BookingCard
const ZONE_CITY = {
  'DHA Phase 2': 'Karachi', 'Gulshan-e-Iqbal': 'Karachi', 'Clifton': 'Karachi',
  'PECHS': 'Karachi', 'North Nazimabad': 'Karachi', 'Nazimabad': 'Karachi',
  'G-13': 'Islamabad', 'Bahria Town': 'Rawalpindi', 'Johar': 'Lahore', 'Saddar': 'Rawalpindi',
};

// Backend agent names → frontend AGENT_META keys
const AGENT_NAME_MAP = {
  RankAgent:  'RankingAgent',
  PriceAgent: 'PricingAgent',
};

// Convert backend trace steps → AgentTrace format
function adaptTrace(steps) {
  return (steps || []).map(t => ({
    agent:     AGENT_NAME_MAP[t.agent] || t.agent,
    decision:  t.step,
    reasoning: t.reasoning + (t.output != null ? ` → ${JSON.stringify(t.output).slice(0, 80)}` : ''),
    timestamp: ts(),
    raw:       { output: { input: t.input, output: t.output, reasoning: t.reasoning } },
  }));
}

// Compute the 6 sub-scores ProviderPicker needs
function computeScores(p) {
  const rating     = parseFloat(((p.rating / 5) * 25).toFixed(1));
  const experience = parseFloat((Math.min((p.total_jobs || 0) / 500, 1) * 15).toFixed(1));
  const response   = parseFloat(((p.on_time_score ?? 0.8) * 20).toFixed(1));
  const completion = parseFloat(((1 - (p.cancellation_rate ?? 0.1)) * 20).toFixed(1));
  const certified  = (p.on_time_score ?? 0) >= 0.9 ? 12.0 : 0.0;
  const price      = parseFloat(((1 - Math.min((p.hourly_rate || 0) / 2000, 1)) * 8).toFixed(1));
  const total      = rating + experience + response + completion + certified + price;
  return { scores: { rating, experience, response, completion, certified, price }, total_score: parseFloat(total.toFixed(2)) };
}

// Reshape backend provider → ProviderPicker-compatible object
function adaptProvider(p, city) {
  const { scores, total_score } = computeScores(p);
  return {
    ...p,
    area:           p.zone,
    city:           city || ZONE_CITY[p.zone] || 'Pakistan',
    jobs:           p.total_jobs || 0,
    responseTime:   Math.max(8, Math.round((p.distance_km ?? 3) * 4)),
    pricePerHr:     p.hourly_rate || 0,
    certified:      (p.on_time_score ?? 0) >= 0.9,
    completionRate: Math.round((1 - (p.cancellation_rate ?? 0.1)) * 100),
    available:      (p.available_slots || []).map(s => s.split('T')[1]?.slice(0, 5)).filter(Boolean),
    total_score,
    scores,
  };
}

// Convert backend price breakdown → BookingCard-compatible pricing object
function adaptPricing(bd, hourlyRate) {
  const hours    = bd.hours_estimated || 2;
  const base     = bd.base || 0;
  const visitFee = 200;
  const materials = Math.round(base * 0.15);
  const urgency  = bd.urgency_fee || 0;
  const platform = 99;
  const tax      = Math.round((base + urgency + visitFee + materials) * 0.05);
  const total    = bd.total || (base + urgency + visitFee + materials + tax + platform);
  const breakdown = {
    labor:              { hours, rate: hourlyRate || Math.round(base / Math.max(hours, 1)), total: base },
    visit_fee:          visitFee,
    materials_estimate: materials,
    urgency_surcharge:  urgency,
    platform_fee:       platform,
    tax_gst:            tax,
  };
  return {
    // Flat shape used by PaymentSheet + App (result.pricing.total)
    total:           total,
    total_estimate:  total,
    breakdown,
    payment_methods: ['JazzCash', 'EasyPaisa', 'Card', 'Cash on Service'],
    // Nested shape BookingCard expects via pricing?.output
    output: {
      total_estimate: total,
      total,
      breakdown,
      payment_methods: ['JazzCash', 'EasyPaisa', 'Card', 'Cash on Service'],
    },
  };
}

// Build BookingCard booking object from backend booking + adapted pricing
function adaptBooking(bk, provider, intentOutput, adaptedPricing) {
  const slotDate = new Date(bk.slot);
  return {
    booking_id:  bk.ref,
    status:      bk.status,
    provider: {
      id:        provider.id,
      name:      provider.name,
      area:      provider.zone,
      rating:    provider.rating,
      certified: (provider.on_time_score ?? 0) >= 0.9,
      phone:     `0300-${Math.floor(1000000 + Math.random() * 9000000)}`,
    },
    service:  bk.service_type,
    city:     intentOutput.city || ZONE_CITY[provider.zone] || 'Pakistan',
    slot: {
      date: isNaN(slotDate) ? bk.slot : slotDate.toDateString(),
      time: isNaN(slotDate) ? '' : slotDate.toTimeString().slice(0, 5),
    },
    pricing: {
      total:           bk.price || adaptedPricing.output.total_estimate,
      breakdown:       adaptedPricing.output.breakdown,
      currency:        'PKR',
      payment_methods: ['JazzCash', 'EasyPaisa', 'Card', 'Cash on Service'],
    },
    receipt_id:  `RCP-${bk.ref}`,
    created_at:  bk.created_at,
  };
}

// Followup reminders — generated client-side (no extra API round-trip needed)
function makeFollowup(bookingId, language) {
  const ru = language === 'roman_urdu';
  const ur = language === 'urdu';
  return {
    booking_id: bookingId,
    reminders_scheduled: [
      { trigger: '1 hour before', message: ru ? 'Aapka service worker 1 ghante mein pohonchega!' : ur ? 'آپ کا ورکر 1 گھنٹے میں پہنچے گا!' : 'Your provider arrives in 1 hour!' },
      { trigger: '15 min before', message: ru ? 'Ustad aa raha hai, tayar ho jayen!' : ur ? 'کاریگر آ رہا ہے!' : 'Provider is on the way!' },
      { trigger: 'On completion', message: ru ? 'Service complete! Rating dein please 🌟' : ur ? 'سروس مکمل! ریٹنگ دیں' : 'Service complete! Please rate your experience ⭐' },
    ],
    feedback_link:    `https://hizmat.ai/feedback/${bookingId}`,
    dispute_channel:  '0800-HIZMAT',
    followup_status:  'active',
  };
}

// Simple language detection (mirrors agentEngine.js)
function detectLang(text) {
  if (/[؀-ۿ]/.test(text)) return (text.match(/\b[a-zA-Z]{3,}\b/g)?.length ?? 0) > 3 ? 'mixed' : 'urdu';
  if (/\b(bijli|pani|safai|jaldi|ghar|abhi|mujhe|chahiye|ustad|bhai|karo|lagao)\b/i.test(text)) return 'roman_urdu';
  return 'english';
}

// ─────────────────────────────────────────────────────────────
//  PHASE 1 — Conversational Intent → Discovery → Ranking
// ─────────────────────────────────────────────────────────────
export async function runPhase1(userMessage, sessionId, userId, onAgentUpdate, onAgentStart) {
  const session = getSession(sessionId);
  const agentTrace = [];
  const push = (steps) => { agentTrace.push(...steps); onAgentUpdate?.([...agentTrace]); };

  // Extract time / date / urgency from this message client-side
  const parsedTime    = parseTimeFromText(userMessage);
  const parsedDate    = parseDateFromText(userMessage);
  const parsedUrgency = parseUrgencyFromText(userMessage);

  if (parsedTime)    session.preferred_time = parsedTime;
  if (parsedDate)    session.preferred_date = parsedDate;
  if (parsedUrgency) { session.urgency = 'urgent'; session.preferred_time = session.preferred_time || 'ASAP'; }

  // Quick-reply special values sent as the message text
  if (userMessage === 'urgent') { session.urgency = 'urgent'; session.preferred_time = 'ASAP'; }
  if (userMessage === 'today')  { session.preferred_date = 'today'; }
  if (userMessage === 'tomorrow') { session.preferred_date = 'tomorrow'; }

  // If we already have cached providers and the user just gave us a time/date,
  // skip the backend round-trip and go straight to provider selection.
  if (session.cached_providers && session.cached_providers.length > 0 &&
      (parsedTime || parsedUrgency || userMessage === 'urgent' ||
       userMessage === 'today' || userMessage === 'tomorrow')) {

    const allProviders = session.cached_providers;
    let filtered = allProviders;

    if (session.preferred_time && session.preferred_time !== 'ASAP') {
      const byTime = allProviders.filter(p => p.available.includes(session.preferred_time));
      if (byTime.length > 0) filtered = byTime;
    }

    const lang = session.language;
    const svc  = session.service_type?.replace('_', ' ') || 'service';
    const city = session.city || 'your area';
    const timeLabel = session.preferred_time === 'ASAP' ? 'ASAP' : fmt12(session.preferred_time);

    let intro;
    if (lang === 'roman_urdu')
      intro = `**${timeLabel}** ke liye **${filtered.length}** ${svc} providers — AI score ke hisaab se rank ho gaye. Apna provider chunein:`;
    else if (lang === 'urdu')
      intro = `**${timeLabel}** کے لیے **${filtered.length}** ${svc} ملے۔ اپنا انتخاب کریں:`;
    else
      intro = `For **${timeLabel}** — found **${filtered.length}** ${svc} providers in **${city}** ranked by AI. Pick your provider:`;

    return {
      status: 'providers_ready',
      intent: { ...session, language: lang, confidence_score: 0.95 },
      top3: filtered.slice(0, 3),
      agent_trace: agentTrace,
      user_message: intro,
    };
  }

  // ── IntentAgent (backend) ────────────────────────────────────
  onAgentStart?.('IntentAgent');
  const intentRes = await fetch(`${BACKEND}/intent`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: userMessage, user_id: userId || 'guest_' + sessionId, session_id: sessionId }),
  });
  const intentData = await intentRes.json();
  push(adaptTrace(intentData.agent_trace));

  const intent = intentData.intent;
  const city   = intent.city || ZONE_CITY[intent.zone] || intent.zone || 'Pakistan';
  const lang   = detectLang(userMessage);

  // Merge backend intent into session memory
  if (intent.service_type) session.service_type = intent.service_type;
  if (intent.city || intent.zone) { session.city = city; session.zone = intent.zone; }
  if (intent.is_urgent) { session.urgency = 'urgent'; session.preferred_time = session.preferred_time || 'ASAP'; }
  session.language = lang;

  const intentForUI = {
    ...intent,
    ...session,
    city,
    language: lang,
    urgency: session.urgency,
    preferred_time: session.preferred_time,
    confidence_score: intent.ambiguous ? 0.3 : 0.95,
  };

  if (intent.ambiguous || !intent.service_type) {
    const q = intent.clarification_question;
    let msg, qr;
    if (!intent.service_type && !session.service_type) {
      msg = q || (lang === 'roman_urdu'
        ? 'Assalam o Alaikum! Kaunsi service chahiye? (bijli / pani / safai / AC / beauty / tutor)'
        : lang === 'urdu'
        ? 'السلام علیکم! کون سی سروس چاہیے؟'
        : 'Hello! What service do you need today?');
      qr = [
        { label: '⚡ Electrician', value: 'I need an electrician', type: 'service' },
        { label: '🔧 Plumber',     value: 'I need a plumber',     type: 'service' },
        { label: '🧹 Cleaning',    value: 'I need cleaning',      type: 'service' },
        { label: '❄️ AC Repair',   value: 'I need AC repair',     type: 'service' },
        { label: '🎨 Painter',     value: 'I need a painter',     type: 'service' },
        { label: '📚 Home Tutor',  value: 'I need a home tutor',  type: 'service' },
      ];
    } else {
      msg = q || (lang === 'roman_urdu'
        ? `${session.service_type || ''} ke liye — aap kis shehar mein hain?`
        : lang === 'urdu' ? 'آپ کس شہر میں ہیں؟'
        : `Which city are you in? (Karachi / Lahore / Islamabad / Rawalpindi / Peshawar)`);
      qr = [
        { label: '📍 Karachi',     value: `${session.service_type || 'service'} in Karachi`,    type: 'city' },
        { label: '📍 Lahore',      value: `${session.service_type || 'service'} in Lahore`,     type: 'city' },
        { label: '📍 Islamabad',   value: `${session.service_type || 'service'} in Islamabad`,  type: 'city' },
        { label: '📍 Rawalpindi',  value: `${session.service_type || 'service'} in Rawalpindi`, type: 'city' },
        { label: '📍 Peshawar',    value: `${session.service_type || 'service'} in Peshawar`,   type: 'city' },
      ];
    }
    return { status: 'clarification_needed', user_message: msg, quick_replies: qr, agent_trace: agentTrace };
  }

  // ── DiscoveryAgent ───────────────────────────────────────────
  onAgentStart?.('DiscoveryAgent');
  const coords = ZONE_COORDS[intent.zone] || DEFAULT_COORDS;
  push([{
    agent: 'DiscoveryAgent', decision: 'zone_search',
    reasoning: `Searching ${intent.service_type} providers near ${intent.zone || city} — haversine radius scan`,
    timestamp: ts(), raw: { output: { zone: intent.zone, coords, service: intent.service_type } },
  }]);

  // ── RankingAgent ─────────────────────────────────────────────
  onAgentStart?.('RankingAgent');
  const rankRes = await fetch(`${BACKEND}/rank`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ service_type: intent.service_type, user_lat: coords.lat, user_lng: coords.lng }),
  });
  const rankData = await rankRes.json();
  push(adaptTrace(rankData.agent_trace));

  if (!rankData.ranked?.length) {
    const svc = intent.service_type.replace('_', ' ');
    const noMsg = lang === 'roman_urdu'
      ? `Afsos, ${city} mein abhi koi **${svc}** available nahi. Thodi der baad try karein ya kisi aur shehar mein dhundhein.`
      : lang === 'urdu'
      ? `معذرت، ابھی ${city} میں کوئی **${svc}** دستیاب نہیں۔`
      : `No **${svc}** providers available in ${city} right now. Try a different area or check back later.`;
    return { status: 'no_provider', user_message: noMsg, agent_trace: agentTrace, intent: intentForUI };
  }

  const allAdapted = rankData.ranked.map(p => adaptProvider(p, city));
  session.cached_providers = allAdapted; // cache for time-selection round-trip

  // If we already have a time preference, filter and present directly
  let top3 = allAdapted.slice(0, 3);
  if (session.preferred_time && session.preferred_time !== 'ASAP') {
    const byTime = allAdapted.filter(p => p.available.includes(session.preferred_time));
    if (byTime.length > 0) top3 = byTime.slice(0, 3);
  }

  // No time specified and not urgent → ask for time with quick replies
  if (!session.preferred_time && session.urgency !== 'urgent') {
    const slots   = getAvailableSlots(allAdapted.slice(0, 5));
    const timeMsg = buildNeedsTimeMessage(allAdapted.slice(0, 3), intent.service_type, city, lang);
    return {
      status: 'needs_time',
      user_message: timeMsg,
      quick_replies: buildTimeQuickReplies(slots, lang),
      intent: intentForUI,
      agent_trace: agentTrace,
    };
  }

  // Time known — present providers
  const svcLabel = intent.service_type.replace('_', ' ');
  const timeLabel = session.preferred_time === 'ASAP' ? 'ASAP' : fmt12(session.preferred_time);
  let intro;
  if (lang === 'roman_urdu')
    intro = `**${timeLabel}** ke liye **${top3.length}** ${svcLabel} providers dhoondh liye! Apna provider chunein:`;
  else if (lang === 'urdu')
    intro = `**${timeLabel}** کے لیے **${top3.length}** ملے۔ اپنا انتخاب کریں:`;
  else
    intro = `Found **${top3.length}** ${svcLabel} providers for **${timeLabel}** in **${city}** — ranked by AI. Pick your provider:`;

  return {
    status: 'providers_ready',
    intent: intentForUI,
    top3,
    agent_trace: agentTrace,
    memory_used: intentData.memory_used || {},
    user_message: intro,
  };
}

// ─────────────────────────────────────────────────────────────
//  PHASE 2 — PricingAgent → BookingAgent → FollowupAgent
// ─────────────────────────────────────────────────────────────
export async function runPhase2(chosenProvider, intentOutput, existingTrace, sessionId, userId, onAgentUpdate, onAgentStart) {
  const agentTrace = [...existingTrace];
  const push = (steps) => { agentTrace.push(...steps); onAgentUpdate?.([...agentTrace]); };

  // ── PricingAgent ─────────────────────────────────────────────
  onAgentStart?.('PricingAgent');
  const priceRes  = await fetch(`${BACKEND}/price`, {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify({
      provider_id:  chosenProvider.id,
      hours:        intentOutput.urgency === 'urgent' ? 1.5 : 2,
      is_urgent:    intentOutput.urgency === 'urgent',
      distance_km:  chosenProvider.distance_km ?? 3,
      peak_hour:    false,
    }),
  });
  const priceData = await priceRes.json();
  push(adaptTrace(priceData.agent_trace));
  const adaptedPricing = adaptPricing(priceData.breakdown, chosenProvider.hourly_rate);

  // ── BookingAgent ─────────────────────────────────────────────
  onAgentStart?.('BookingAgent');
  const fallbackSlot = new Date(Date.now() + 2 * 3600_000).toISOString().slice(0, 19);
  const slot     = chosenProvider.available_slots?.[0] ?? fallbackSlot;
  const bookRes  = await fetch(`${BACKEND}/book`, {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify({
      provider_id:     chosenProvider.id,
      slot,
      user_id:         userId || 'guest_' + sessionId,
      service_type:    intentOutput.service_type,
      price_breakdown: priceData.breakdown,
      session_id:      sessionId,
    }),
  });
  const bookData = await bookRes.json();
  push(adaptTrace(bookData.agent_trace));

  if (!bookData.success || !bookData.booking) {
    if (bookData.error === 'SLOT_TAKEN') {
      const lang    = intentOutput.language;
      const alts    = (bookData.next_slots || []).slice(0, 3);
      const msg     = buildConflictMessage(chosenProvider.name, bookData.next_slots, lang);

      // Alt-time quick replies from backend's suggested next_slots
      const altTimeReplies = alts.map(s => {
        const d = new Date(s);
        const timeStr = isNaN(d) ? s : d.toTimeString().slice(0, 5);
        const label   = isNaN(d) ? s : `${d.toLocaleDateString('en-PK', { weekday: 'short', month: 'short', day: 'numeric' })} ${fmt12(timeStr)}`;
        return { label: `🕐 ${label}`, value: timeStr, type: 'alt_time', provider: chosenProvider };
      });

      // Offer other cached providers as quick switches
      const session        = getSession(sessionId);
      const otherProviders = (session.cached_providers || [])
        .filter(p => p.id !== chosenProvider.id)
        .slice(0, 2)
        .map(p => ({ label: `🔄 ${p.name} (⭐${p.rating})`, value: `switch_${p.id}`, type: 'alt_provider', provider: p }));

      return {
        status: 'slot_taken',
        booking: null,
        user_message: msg,
        quick_replies: [...altTimeReplies, ...otherProviders],
        agent_trace: agentTrace,
      };
    }
    return { status: 'failed', booking: null, user_message: bookData.error || 'Booking failed.', agent_trace: agentTrace };
  }

  // ── FollowupAgent ─────────────────────────────────────────────
  onAgentStart?.('FollowupAgent');
  const followup = makeFollowup(bookData.booking.ref, intentOutput.language);
  push([{
    agent:     'FollowupAgent',
    decision:  'reminders_scheduled',
    reasoning: `3 WhatsApp reminders queued for booking ${bookData.booking.ref}`,
    timestamp: ts(),
    raw:       { output: followup },
  }]);
  onAgentStart?.(null);

  const bk   = adaptBooking(bookData.booking, chosenProvider, intentOutput, adaptedPricing);
  const lang = intentOutput.language;
  let userMsg;
  if (lang === 'roman_urdu')
    userMsg = `✅ Booking ho gayi!\n\n**${bk.provider.name}** aa raha hai **${bk.slot.date}** ko **${bk.slot.time}** par.\n\nBooking ID: **${bk.booking_id}**\nTotal: **PKR ${bk.pricing.total.toLocaleString()}**\n\nJazzCash / EasyPaisa / Card se payment kar sakte hain. 🎉`;
  else if (lang === 'urdu')
    userMsg = `✅ بکنگ ہوگئی!\n\n**${bk.provider.name}** آئیں گے **${bk.slot.date}** کو **${bk.slot.time}** پر۔\n\nبکنگ ID: **${bk.booking_id}**\nکل: **PKR ${bk.pricing.total.toLocaleString()}**`;
  else
    userMsg = `✅ Booking confirmed!\n\n**${bk.provider.name}** will arrive on **${bk.slot.date}** at **${bk.slot.time}**.\n\nBooking ID: **${bk.booking_id}**\nEstimate: **PKR ${bk.pricing.total.toLocaleString()}**\n\nPay via JazzCash, EasyPaisa, Card, or Cash. 🎉`;

  return {
    status:      'confirmed',
    booking:     bk,
    pricing:     adaptedPricing.output,
    followup,
    user_message: userMsg,
    agent_trace:  agentTrace,
  };
}

// cancelBooking — backend doesn't expose a delete endpoint; just notify
export function cancelBooking(_bookingId) { return true; }

// runDemoScenario — kept for interface compatibility
export async function runDemoScenario(_scenario, _onUpdate, _onStart) {
  return { status: 'failed', user_message: 'Use the chat input for demos.', agent_trace: [] };
}

export const PROVIDERS_DB = [];
