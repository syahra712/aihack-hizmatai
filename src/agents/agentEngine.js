// ─────────────────────────────────────────────────────────────
//  HizmatAI — Agent Engine v2  (6 sub-agents, two-phase booking)
// ─────────────────────────────────────────────────────────────

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ── Providers Database (25 providers, 5 cities) ───────────────
export const PROVIDERS_DB = [
  // Karachi — Electrician
  { id: "P001", name: "Ustad Tariq Electric",    service: "electrician", city: "Karachi",   area: "Gulshan-e-Iqbal",  rating: 4.8, jobs: 312, pricePerHr: 800,  available: ["09:00","10:00","11:00","14:00","15:00"], certified: true,  responseTime: 12, completionRate: 97 },
  { id: "P009", name: "SparkSafe Electric",       service: "electrician", city: "Karachi",   area: "PECHS",            rating: 4.6, jobs: 278, pricePerHr: 820,  available: ["11:00","14:00","15:00","16:00"],         certified: true,  responseTime: 15, completionRate: 96 },
  // Karachi — Plumber
  { id: "P002", name: "Ali Brothers Plumbing",    service: "plumber",     city: "Karachi",   area: "DHA Phase 5",      rating: 4.6, jobs: 198, pricePerHr: 700,  available: ["08:00","09:00","13:00","16:00"],         certified: true,  responseTime: 18, completionRate: 94 },
  { id: "P011", name: "HydroFix Karachi",         service: "plumber",     city: "Karachi",   area: "Nazimabad",        rating: 4.4, jobs: 134, pricePerHr: 680,  available: ["09:00","11:00","14:00"],                 certified: false, responseTime: 22, completionRate: 91 },
  // Karachi — Cleaning
  { id: "P010", name: "GreenMop Cleaning",        service: "cleaning",    city: "Karachi",   area: "Gulshan-e-Iqbal",  rating: 4.8, jobs: 390, pricePerHr: 550,  available: ["09:00","10:00","12:00","14:00"],         certified: true,  responseTime: 12, completionRate: 97 },
  { id: "P012", name: "CleanNest Karachi",        service: "cleaning",    city: "Karachi",   area: "Clifton",          rating: 4.5, jobs: 220, pricePerHr: 600,  available: ["10:00","11:00","15:00","16:00"],         certified: true,  responseTime: 14, completionRate: 95 },
  // Karachi — AC Repair
  { id: "P004", name: "Khalid AC & Cooling",      service: "ac_repair",   city: "Karachi",   area: "North Nazimabad",  rating: 4.5, jobs: 145, pricePerHr: 1200, available: ["09:00","12:00","15:00"],                 certified: false, responseTime: 25, completionRate: 91 },
  { id: "P013", name: "ArcticCool Karachi",       service: "ac_repair",   city: "Karachi",   area: "DHA Phase 2",      rating: 4.7, jobs: 201, pricePerHr: 1150, available: ["08:00","10:00","13:00","16:00"],         certified: true,  responseTime: 18, completionRate: 95 },
  // Karachi — Home Tutor
  { id: "P014", name: "Sir Ahmed Academics",      service: "home_tutor",  city: "Karachi",   area: "Gulshan-e-Iqbal",  rating: 4.9, jobs: 87,  pricePerHr: 900,  available: ["16:00","17:00","18:00"],                 certified: true,  responseTime: 30, completionRate: 99 },
  { id: "P015", name: "BrightMinds Tutoring",     service: "home_tutor",  city: "Karachi",   area: "PECHS",            rating: 4.7, jobs: 64,  pricePerHr: 850,  available: ["15:00","16:00","17:00","18:00"],         certified: true,  responseTime: 35, completionRate: 97 },
  // Karachi — Beautician
  { id: "P016", name: "Rina Beauty at Home",      service: "beautician",  city: "Karachi",   area: "DHA Phase 6",      rating: 4.9, jobs: 312, pricePerHr: 1000, available: ["10:00","12:00","14:00","16:00"],         certified: true,  responseTime: 20, completionRate: 98 },
  { id: "P017", name: "Glam Squad Karachi",       service: "beautician",  city: "Karachi",   area: "Clifton",          rating: 4.7, jobs: 198, pricePerHr: 950,  available: ["11:00","13:00","15:00"],                 certified: false, responseTime: 25, completionRate: 94 },
  // Lahore
  { id: "P003", name: "CleanPro Services",        service: "cleaning",    city: "Lahore",    area: "Johar Town",       rating: 4.9, jobs: 520, pricePerHr: 500,  available: ["10:00","11:00","14:00","15:00","16:00"], certified: true,  responseTime: 8,  completionRate: 99 },
  { id: "P006", name: "Noor Painting Co.",        service: "painter",     city: "Lahore",    area: "Gulberg",          rating: 4.4, jobs: 203, pricePerHr: 650,  available: ["08:00","09:00","13:00"],                 certified: false, responseTime: 30, completionRate: 89 },
  { id: "P007", name: "Swift Electricians",       service: "electrician", city: "Lahore",    area: "Model Town",       rating: 4.7, jobs: 410, pricePerHr: 850,  available: ["09:00","10:00","11:00","13:00","16:00"], certified: true,  responseTime: 10, completionRate: 98 },
  { id: "P018", name: "Lahore Beauty Experts",    service: "beautician",  city: "Lahore",    area: "DHA Lahore",       rating: 4.8, jobs: 275, pricePerHr: 900,  available: ["10:00","12:00","14:00","16:00"],         certified: true,  responseTime: 18, completionRate: 97 },
  { id: "P019", name: "PakClean Lahore",          service: "cleaning",    city: "Lahore",    area: "Model Town",       rating: 4.6, jobs: 180, pricePerHr: 480,  available: ["09:00","11:00","14:00","16:00"],         certified: false, responseTime: 20, completionRate: 92 },
  // Islamabad
  { id: "P005", name: "Hassan Carpenter Works",   service: "carpenter",   city: "Islamabad", area: "F-7",              rating: 4.7, jobs: 87,  pricePerHr: 900,  available: ["10:00","11:00","14:00"],                 certified: true,  responseTime: 20, completionRate: 95 },
  { id: "P008", name: "AquaFix Plumbing",         service: "plumber",     city: "Islamabad", area: "G-9",              rating: 4.3, jobs: 65,  pricePerHr: 750,  available: ["10:00","15:00","16:00"],                 certified: false, responseTime: 35, completionRate: 88 },
  { id: "P020", name: "Capital Tutor Hub",        service: "home_tutor",  city: "Islamabad", area: "F-8",              rating: 4.8, jobs: 112, pricePerHr: 1000, available: ["15:00","16:00","17:00","18:00"],         certified: true,  responseTime: 25, completionRate: 98 },
  { id: "P021", name: "IslamabadElectric Co.",    service: "electrician", city: "Islamabad", area: "G-11",             rating: 4.5, jobs: 145, pricePerHr: 870,  available: ["09:00","11:00","13:00","15:00"],         certified: true,  responseTime: 17, completionRate: 94 },
  // Rawalpindi
  { id: "P022", name: "RWP Handyman Plus",        service: "carpenter",   city: "Rawalpindi", area: "Saddar",          rating: 4.4, jobs: 98,  pricePerHr: 800,  available: ["09:00","11:00","14:00","16:00"],         certified: false, responseTime: 28, completionRate: 90 },
  { id: "P023", name: "AquaPro Rawalpindi",       service: "plumber",     city: "Rawalpindi", area: "Bahria Town",     rating: 4.6, jobs: 132, pricePerHr: 720,  available: ["08:00","10:00","13:00","15:00"],         certified: true,  responseTime: 22, completionRate: 93 },
  // Peshawar
  { id: "P024", name: "Pesh Clean Squad",         service: "cleaning",    city: "Peshawar",  area: "University Town",  rating: 4.5, jobs: 88,  pricePerHr: 450,  available: ["09:00","11:00","14:00"],                 certified: false, responseTime: 30, completionRate: 91 },
  { id: "P025", name: "Khyber Electric Works",    service: "electrician", city: "Peshawar",  area: "Hayatabad",        rating: 4.3, jobs: 72,  pricePerHr: 760,  available: ["10:00","12:00","15:00"],                 certified: true,  responseTime: 22, completionRate: 89 },
];

// ── Keyword Maps ─────────────────────────────────────────────
const SERVICE_KEYWORDS = {
  electrician: ["bijli","electric","current","wiring","switch","socket","fan","light","mcb","circuit","electrician","bijlee","electrical","لائٹ","بجلی","وائرنگ"],
  plumber:     ["pani","pipe","leakage","nali","bathroom","toilet","tap","plumber","پانی","نلکا","پلمبر","leak","water","drain","blockage"],
  cleaning:    ["safai","clean","sweep","mop","ghar","house","صفائی","cleaning","jharu","dust","scrub","washing"],
  ac_repair:   ["ac","air condition","cooling","heat","thanda","گرمی","ٹھنڈا","compressor","gas","aircon","AC"],
  carpenter:   ["wood","furniture","door","window","shelves","carpenter","لکڑی","الماری","wardro","repair wood","almari"],
  painter:     ["paint","colour","color","wall","rang","رنگ","پینٹ","painting","plaster","whitewash"],
  home_tutor:  ["tutor","teacher","ustad","parhai","padhai","teacher","math","science","english class","home class","استاد","ٹیوٹر","پڑھائی"],
  beautician:  ["beauty","facial","waxing","makeup","bridal","salon","mehendi","threading","eyebrow","hair","parlour","parlor","بیوٹیشن","مہندی"],
};

const CITY_KEYWORDS = {
  Karachi:    ["karachi","khi","کراچی"],
  Lahore:     ["lahore","lhr","لاہور"],
  Islamabad:  ["islamabad","isb","اسلام آباد"],
  Rawalpindi: ["rawalpindi","rwp","راولپنڈی","pindi"],
  Peshawar:   ["peshawar","pesh","پشاور"],
};

const URGENCY_KEYWORDS = {
  urgent:    ["urgent","jaldi","abhi","now","emergency","فوری","ابھی","ضروری","asap","immediately","turant"],
  scheduled: ["kal","tomorrow","next week","agle","schedule","agla","کل"],
};

// ── Language Detector ─────────────────────────────────────────
function detectLanguage(text) {
  const urduScript   = /[؀-ۿ]/.test(text);
  const englishWords = text.match(/\b[a-zA-Z]{3,}\b/g)?.length || 0;
  if (urduScript && englishWords > 3) return "mixed";
  if (urduScript) return "urdu";
  if (/\b(bijli|pani|safai|jaldi|ghar|abhi|mujhe|chahiye|ustad|bhai|karo|lagao|karwani|chahia)\b/i.test(text)) return "roman_urdu";
  return "english";
}

function ts() { return new Date().toISOString(); }

// ─────────────────────────────────────────────────────────────
//  AGENT 1 — IntentAgent
// ─────────────────────────────────────────────────────────────
export async function IntentAgent(userMessage, prevContext = {}) {
  await sleep(500 + Math.random() * 400);
  const msg  = userMessage.toLowerCase();
  const lang = detectLanguage(userMessage);

  let detectedService = prevContext.service_type || null;
  for (const [svc, kws] of Object.entries(SERVICE_KEYWORDS)) {
    if (kws.some((k) => msg.includes(k.toLowerCase()))) { detectedService = svc; break; }
  }

  let detectedCity = prevContext.city || null;
  for (const [city, kws] of Object.entries(CITY_KEYWORDS)) {
    if (kws.some((k) => msg.includes(k.toLowerCase()))) { detectedCity = city; break; }
  }

  // Time extraction
  const timeMatch = msg.match(/\b(\d{1,2})(?::(\d{2}))?\s*(am|pm|baje|bajay)?\b/i);
  let preferredTime = prevContext.preferred_time || null;
  if (timeMatch) {
    let hr = parseInt(timeMatch[1]);
    const min    = timeMatch[2] || "00";
    const period = timeMatch[3]?.toLowerCase();
    if (period === "pm" && hr !== 12) hr += 12;
    if (period === "am" && hr === 12) hr = 0;
    if (hr >= 7 && hr <= 20) preferredTime = `${String(hr).padStart(2,"0")}:${min}`;
  }

  let urgency = prevContext.urgency || "scheduled";
  if (URGENCY_KEYWORDS.urgent.some((k) => msg.includes(k.toLowerCase())))    urgency = "urgent";
  if (URGENCY_KEYWORDS.scheduled.some((k) => msg.includes(k.toLowerCase()))) urgency = "scheduled";

  let confidence = 0.0;
  if (detectedService) confidence += 0.55;
  if (detectedCity)    confidence += 0.25;
  if (preferredTime || urgency === "urgent") confidence += 0.15;
  if (!detectedService && !detectedCity) confidence = 0.30;

  let clarification = null;
  if (confidence < 0.75) {
    if (!detectedService && !detectedCity) {
      if (lang === "roman_urdu") clarification = "Bhai, kaunsi service chahiye (bijli/pani/safai/AC/beauty/tutor) aur aap kis shehar mein hain? 🙏";
      else if (lang === "urdu") clarification = "جناب، کون سی سروس چاہیے اور آپ کس شہر میں ہیں؟";
      else clarification = "Which service do you need and in which city? (Karachi / Lahore / Islamabad / Rawalpindi / Peshawar)";
    } else if (!detectedService) {
      if (lang === "roman_urdu") clarification = "Kaunsi service chahiye? Bijli, pani, safai, AC, beauty, ya tutor?";
      else if (lang === "urdu") clarification = "کون سی سروس درکار ہے؟ بجلی، پانی، صفائی، یا کچھ اور؟";
      else clarification = `Got it — you're in ${detectedCity}. What service do you need?`;
    } else {
      if (lang === "roman_urdu") clarification = `${detectedService} ke liye — aap kis shehar mein hain? (Karachi/Lahore/Islamabad)`;
      else if (lang === "urdu") clarification = `${detectedService} سروس کے لیے — آپ کس شہر میں ہیں؟`;
      else clarification = `For ${detectedService} — which city are you in? (Karachi / Lahore / Islamabad / Rawalpindi / Peshawar)`;
    }
  }

  return {
    agent: "IntentAgent",
    timestamp: ts(),
    output: {
      raw_text: userMessage,
      language: lang,
      service_type: detectedService,
      city: detectedCity,
      preferred_time: preferredTime,
      urgency,
      confidence_score: Math.min(confidence, 0.98),
      clarification_question: clarification,
      entities: { service: detectedService, city: detectedCity, time: preferredTime, urgency },
    }
  };
}

// ─────────────────────────────────────────────────────────────
//  AGENT 2 — DiscoveryAgent
// ─────────────────────────────────────────────────────────────
export async function DiscoveryAgent(intentOutput) {
  await sleep(700 + Math.random() * 400);
  const { service_type, city, urgency, preferred_time } = intentOutput;

  let providers = PROVIDERS_DB.filter(
    (p) => p.service === service_type && p.city === city
  );

  if (urgency === "urgent") {
    const fast = providers.filter((p) => p.responseTime <= 20);
    if (fast.length > 0) providers = fast;
  }

  if (preferred_time) {
    const avail = providers.filter((p) => p.available.includes(preferred_time));
    if (avail.length > 0) providers = avail;
  }

  const waitlist = providers.length === 0;
  let nextSlot = null;
  if (waitlist) {
    const anyProviders = PROVIDERS_DB.filter((p) => p.service === service_type);
    if (anyProviders.length > 0) {
      const tomorrow = new Date(); tomorrow.setDate(tomorrow.getDate() + 1);
      nextSlot = { date: tomorrow.toDateString(), time: "10:00", provider: anyProviders[0].name, city: anyProviders[0].city };
    }
  }

  return {
    agent: "DiscoveryAgent",
    timestamp: ts(),
    output: {
      providers_found: providers.length,
      providers,
      waitlist_mode: waitlist,
      next_available_slot: nextSlot,
      search_params: { service_type, city, urgency, preferred_time },
    }
  };
}

// ─────────────────────────────────────────────────────────────
//  AGENT 3 — RankingAgent  (returns top 3)
// ─────────────────────────────────────────────────────────────
export async function RankingAgent(discoveryOutput, skipIds = []) {
  await sleep(600 + Math.random() * 300);
  const { providers, search_params } = discoveryOutput;

  const scored = providers
    .filter((p) => !skipIds.includes(p.id))
    .map((p) => {
      const ratingScore     = (p.rating / 5) * 25;
      const jobsScore       = Math.min(p.jobs / 500, 1) * 15;
      const responseScore   = (1 - Math.min(p.responseTime / 60, 1)) * 20;
      const completionScore = (p.completionRate / 100) * 20;
      const certScore       = p.certified ? 12 : 0;
      const priceScore      = (1 - Math.min(p.pricePerHr / 2000, 1)) * 8;
      const total = ratingScore + jobsScore + responseScore + completionScore + certScore + priceScore;
      return {
        ...p,
        scores: {
          rating:      parseFloat(ratingScore.toFixed(1)),
          experience:  parseFloat(jobsScore.toFixed(1)),
          response:    parseFloat(responseScore.toFixed(1)),
          completion:  parseFloat(completionScore.toFixed(1)),
          certified:   parseFloat(certScore.toFixed(1)),
          price:       parseFloat(priceScore.toFixed(1)),
        },
        total_score: parseFloat(total.toFixed(2)),
      };
    })
    .sort((a, b) => b.total_score - a.total_score);

  return {
    agent: "RankingAgent",
    timestamp: ts(),
    output: {
      ranked_providers: scored,
      top_3: scored.slice(0, 3),
      top_provider: scored[0] || null,
      factors_used: ["rating","experience","response_time","completion_rate","certification","price_competitiveness"],
    }
  };
}

// ─────────────────────────────────────────────────────────────
//  AGENT 4 — PricingAgent
// ─────────────────────────────────────────────────────────────
export async function PricingAgent(provider, intentOutput) {
  await sleep(500 + Math.random() * 300);
  const { urgency } = intentOutput;

  const baseHours        = urgency === "urgent" ? 1.5 : 2;
  const laborCost        = provider.pricePerHr * baseHours;
  const visitFee         = 200;
  const materialEstimate = Math.round(laborCost * 0.3);
  const urgencySurcharge = urgency === "urgent" ? Math.round(laborCost * 0.15) : 0;
  const platformFee      = 99;
  const subtotal         = laborCost + visitFee + materialEstimate + urgencySurcharge;
  const tax              = Math.round(subtotal * 0.05);
  const total            = subtotal + tax + platformFee;

  return {
    agent: "PricingAgent",
    timestamp: ts(),
    output: {
      provider_id: provider.id,
      currency: "PKR",
      breakdown: {
        labor: { hours: baseHours, rate: provider.pricePerHr, total: laborCost },
        visit_fee:           visitFee,
        materials_estimate:  materialEstimate,
        urgency_surcharge:   urgencySurcharge,
        platform_fee:        platformFee,
        tax_gst:             tax,
      },
      subtotal,
      total_estimate: total,
      price_range: { min: Math.round(total * 0.85), max: Math.round(total * 1.2) },
      payment_methods: ["JazzCash","EasyPaisa","Card","Cash on Service"],
    }
  };
}

// ─────────────────────────────────────────────────────────────
//  AGENT 5 — BookingAgent
// ─────────────────────────────────────────────────────────────
const ACTIVE_BOOKINGS = {};

export async function BookingAgent(provider, pricingOutput, intentOutput) {
  await sleep(800 + Math.random() * 400);
  const { preferred_time, urgency } = intentOutput;

  let slotTime = preferred_time;
  if (!slotTime) {
    slotTime = urgency === "urgent"
      ? provider.available[0]
      : provider.available[Math.floor(provider.available.length / 2)];
  }

  const slotKey  = `${provider.id}_${slotTime}`;
  const conflict = !!ACTIVE_BOOKINGS[slotKey];

  if (conflict) {
    return {
      agent: "BookingAgent",
      timestamp: ts(),
      output: { conflict: true, conflicted_provider: provider.id, conflicted_slot: slotTime }
    };
  }

  const now        = new Date();
  const bookingId  = `HZ-${Date.now().toString(36).toUpperCase().slice(-6)}`;
  const bookingDate = urgency === "urgent"
    ? now.toDateString()
    : new Date(now.getTime() + 24 * 60 * 60 * 1000).toDateString();

  const booking = {
    booking_id:  bookingId,
    status:      "confirmed",
    provider: {
      id:       provider.id,
      name:     provider.name,
      area:     provider.area,
      rating:   provider.rating,
      certified: provider.certified,
      phone:    `0300-${Math.floor(1000000 + Math.random() * 9000000)}`,
    },
    service:  intentOutput.service_type,
    city:     intentOutput.city,
    slot:     { date: bookingDate, time: slotTime },
    pricing:  { total: pricingOutput.output.total_estimate, breakdown: pricingOutput.output.breakdown, currency: "PKR", payment_methods: pricingOutput.output.payment_methods },
    receipt_id: `RCP-${bookingId}`,
    created_at: ts(),
  };

  ACTIVE_BOOKINGS[slotKey] = booking;

  return {
    agent: "BookingAgent",
    timestamp: ts(),
    output: { conflict: false, booking }
  };
}

// ─────────────────────────────────────────────────────────────
//  AGENT 6 — FollowupAgent
// ─────────────────────────────────────────────────────────────
export async function FollowupAgent(bookingOutput, intentOutput) {
  await sleep(400 + Math.random() * 200);
  const { booking } = bookingOutput.output;
  const lang        = intentOutput.language;

  const reminderSchedule = [
    { trigger: "1 hour before",   message: lang === "roman_urdu" ? "Aapka service worker 1 ghante mein pohonchega!" : lang === "urdu" ? "آپ کا ورکر 1 گھنٹے میں پہنچے گا!" : "Your provider arrives in 1 hour!" },
    { trigger: "15 min before",   message: lang === "roman_urdu" ? "Ustad aa raha hai, tayar ho jayen!" : lang === "urdu" ? "کاریگر آ رہا ہے!" : "Provider is on the way!" },
    { trigger: "On completion",   message: lang === "roman_urdu" ? "Service complete! Rating dein please 🌟" : lang === "urdu" ? "سروس مکمل! ریٹنگ دیں" : "Service complete! Please rate your experience ⭐" },
  ];

  return {
    agent: "FollowupAgent",
    timestamp: ts(),
    output: {
      booking_id:          booking.booking_id,
      reminders_scheduled: reminderSchedule,
      feedback_link:       `https://hizmat.ai/feedback/${booking.booking_id}`,
      dispute_channel:     "0800-HIZMAT",
      followup_status:     "active",
    }
  };
}

// ── Cancel Booking ────────────────────────────────────────────
export function cancelBooking(bookingId) {
  for (const key of Object.keys(ACTIVE_BOOKINGS)) {
    if (ACTIVE_BOOKINGS[key]?.booking_id === bookingId) {
      delete ACTIVE_BOOKINGS[key]; return true;
    }
  }
  return false;
}

// ─────────────────────────────────────────────────────────────
//  PHASE 1 — Intent → Discovery → Ranking (returns top 3)
//  Returns { status, intent, top3, agentTrace } or { status: "clarification"|"no_provider" }
// ─────────────────────────────────────────────────────────────
export async function runPhase1(userMessage, prevContext, onAgentUpdate, onAgentStart) {
  const agentTrace = [];
  const log = (agent, decision, reasoning, raw) => {
    agentTrace.push({ agent, decision, reasoning, timestamp: ts(), raw });
    onAgentUpdate?.([...agentTrace]);
  };

  onAgentStart?.('IntentAgent');
  const intentResult = await IntentAgent(userMessage, prevContext);
  const intent = intentResult.output;
  log("IntentAgent",
    intent.confidence_score >= 0.75 ? "Proceed" : "Clarify",
    `Detected: ${intent.service_type || "?"} in ${intent.city || "?"} | lang=${intent.language} | conf=${intent.confidence_score.toFixed(2)}`,
    intentResult
  );

  if (intent.confidence_score < 0.75) {
    return { status: "clarification_needed", user_message: intent.clarification_question, agent_trace: agentTrace };
  }

  onAgentStart?.('DiscoveryAgent');
  const discoveryResult = await DiscoveryAgent(intent);
  const discovery = discoveryResult.output;
  log("DiscoveryAgent",
    discovery.waitlist_mode ? "WaitlistMode" : `Found ${discovery.providers_found} providers`,
    `Searched ${intent.service_type} in ${intent.city}`,
    discoveryResult
  );

  if (discovery.waitlist_mode) {
    const slot = discovery.next_available_slot;
    let msg;
    if (intent.language === "roman_urdu")
      msg = `Abhi ${intent.city} mein koi ${intent.service_type.replace("_"," ")} available nahi. Nearest option: ${slot?.provider} (${slot?.city}) — ${slot?.date} at ${slot?.time}. Kya waitlist mein shamil hona chahte hain?`;
    else if (intent.language === "urdu")
      msg = `ابھی ${intent.city} میں کوئی دستیاب نہیں۔ اگلا سلاٹ: ${slot?.date} ${slot?.time}`;
    else
      msg = `No ${intent.service_type.replace("_"," ")} providers available in ${intent.city} right now.\n\nNearest option: **${slot?.provider}** (${slot?.city}) on **${slot?.date}** at **${slot?.time}**.\n\nWould you like to be added to the waitlist?`;
    return { status: "no_provider", user_message: msg, agent_trace: agentTrace, intent };
  }

  onAgentStart?.('RankingAgent');
  const rankingResult = await RankingAgent(discovery);
  const ranking = rankingResult.output;
  log("RankingAgent",
    `Top: ${ranking.top_provider.name} (score: ${ranking.top_provider.total_score})`,
    `Ranked ${ranking.ranked_providers.length} providers by 6 factors`,
    rankingResult
  );

  return {
    status: "providers_ready",
    intent,
    top3: ranking.top_3,
    discovery: discovery,
    ranking: ranking,
    agent_trace: agentTrace,
  };
}

// ─────────────────────────────────────────────────────────────
//  PHASE 2 — Pricing → Booking → Followup (after provider chosen)
// ─────────────────────────────────────────────────────────────
export async function runPhase2(chosenProvider, intentOutput, existingTrace, onAgentUpdate, onAgentStart) {
  const agentTrace = [...existingTrace];
  const log = (agent, decision, reasoning, raw) => {
    agentTrace.push({ agent, decision, reasoning, timestamp: ts(), raw });
    onAgentUpdate?.([...agentTrace]);
  };

  onAgentStart?.('PricingAgent');
  const pricingResult = await PricingAgent(chosenProvider, intentOutput);
  log("PricingAgent",
    `Quote: PKR ${pricingResult.output.total_estimate.toLocaleString()}`,
    `Labor + visit + materials + platform fee + 5% GST`,
    pricingResult
  );

  onAgentStart?.('BookingAgent');
  let bookingResult = await BookingAgent(chosenProvider, pricingResult, intentOutput);
  log("BookingAgent",
    bookingResult.output.conflict ? "Conflict detected" : `Booked: ${bookingResult.output.booking?.booking_id}`,
    bookingResult.output.conflict ? "Double-booking detected — slot already taken" : "Slot confirmed and receipt generated",
    bookingResult
  );

  if (bookingResult.output.conflict) {
    return { status: "failed", booking: null, user_message: "This time slot was just taken. Please choose a different provider or try again.", agent_trace: agentTrace };
  }

  onAgentStart?.('FollowupAgent');
  const followupResult = await FollowupAgent(bookingResult, intentOutput);
  log("FollowupAgent", "Reminders & followup scheduled", `${followupResult.output.reminders_scheduled.length} reminders queued`, followupResult);

  const bk = bookingResult.output.booking;
  let userMsg;
  if (intentOutput.language === "roman_urdu")
    userMsg = `✅ Booking ho gayi, Bhai!\n\n**${bk.provider.name}** aa raha hai **${bk.slot.date}** ko **${bk.slot.time}** par.\n\nBooking ID: **${bk.booking_id}**\nTotal: **PKR ${bk.pricing.total.toLocaleString()}**\n\nJazzCash / EasyPaisa / Card se payment kar sakte hain. 🎉`;
  else if (intentOutput.language === "urdu")
    userMsg = `✅ بکنگ ہوگئی!\n\n**${bk.provider.name}** آئیں گے **${bk.slot.date}** کو **${bk.slot.time}** پر۔\n\nبکنگ ID: **${bk.booking_id}**\nکل: **PKR ${bk.pricing.total.toLocaleString()}**`;
  else
    userMsg = `✅ Booking confirmed!\n\n**${bk.provider.name}** will arrive on **${bk.slot.date}** at **${bk.slot.time}**.\n\nBooking ID: **${bk.booking_id}**\nEstimate: **PKR ${bk.pricing.total.toLocaleString()}**\n\nPay via JazzCash, EasyPaisa, Card, or Cash. 🎉`;

  return {
    status: "confirmed",
    booking: bk,
    pricing: pricingResult.output,
    followup: followupResult.output,
    user_message: userMsg,
    agent_trace: agentTrace,
  };
}

// ─────────────────────────────────────────────────────────────
//  DEMO SCENARIOS  (judge-facing)
// ─────────────────────────────────────────────────────────────
export async function runDemoScenario(scenario, onAgentUpdate, onAgentStart) {
  switch (scenario) {
    case "A_conflict": {
      // Force a conflict by pre-booking the top slot
      const p = PROVIDERS_DB.find(p => p.id === "P001");
      const key = `P001_${p.available[0]}`;
      ACTIVE_BOOKINGS[key] = { booking_id: "DEMO-TAKEN", dummy: true };
      const mockIntent = { service_type: "electrician", city: "Karachi", urgency: "urgent", preferred_time: p.available[0], language: "english" };
      const phase1 = await runPhase1("I need an electrician urgently in Karachi now", {}, onAgentUpdate, onAgentStart);
      if (phase1.status === "providers_ready") {
        const topProvider = phase1.top3[0];
        const result = await runPhase2(topProvider, phase1.intent, phase1.agent_trace, onAgentUpdate, onAgentStart);
        delete ACTIVE_BOOKINGS[key];
        return result;
      }
      return phase1;
    }
    case "B_no_provider":
      return runPhase1("I need a carpenter in Peshawar right now", {}, onAgentUpdate, onAgentStart);
    case "C_clarify":
      return runPhase1("Koi repair wala chahiye", {}, onAgentUpdate, onAgentStart);
    case "D_multilang":
      return runPhase1("AC repair karwani hai, Islamabad mein — کوئی اچھا ملے؟", {}, onAgentUpdate, onAgentStart);
    default:
      return { status: "failed", user_message: "Unknown demo scenario.", agent_trace: [] };
  }
}
