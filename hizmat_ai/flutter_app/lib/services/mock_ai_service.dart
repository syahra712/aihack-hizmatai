import 'dart:math';
import '../models/provider.dart';

class AgentStep {
  final String agent;
  final String action;
  final String detail;
  final DateTime timestamp;
  const AgentStep({required this.agent, required this.action, required this.detail, required this.timestamp});
}

class AiResponse {
  final String message;
  final String detectedService;
  final String detectedCity;
  final List<ServiceProvider> providers;
  final List<AgentStep> trace;
  const AiResponse({
    required this.message,
    required this.detectedService,
    required this.detectedCity,
    required this.providers,
    required this.trace,
  });
}

class MockAiService {
  static final _rng = Random();

  static final _serviceKeywords = <String, List<String>>{
    'electrician': ['bijli', 'electric', 'wiring', 'light', 'switch', 'bijli wala'],
    'plumber': ['pani', 'plumb', 'pipe', 'nalkay', 'toilet', 'drain', 'plumber'],
    'cleaner': ['safai', 'clean', 'jharu', 'house clean', 'ghar safai'],
    'ac_repair': ['ac', 'air condition', 'cooling', 'split', 'inverter', 'thanda'],
    'painter': ['paint', 'rang', 'wall', 'colour', 'color'],
    'carpenter': ['carpenter', 'lakri', 'wood', 'furniture', 'door', 'almari'],
  };

  static final _cityKeywords = <String, List<String>>{
    'Karachi': ['karachi', 'khi', 'dha', 'clifton', 'gulshan', 'nazimabad', 'korangi'],
    'Lahore': ['lahore', 'lhr', 'gulberg', 'johar town', 'model town', 'dha lahore'],
    'Islamabad': ['islamabad', 'isb', 'f-sector', 'g-sector', 'blue area', 'rawalpindi'],
  };

  static final _providerPool = <String, List<ServiceProvider>>{
    'electrician': [
      const ServiceProvider(id: 'e1', name: 'Ustad Arif Electric', serviceType: 'electrician', city: 'Karachi', zone: 'DHA Phase 6', rating: 4.8, reviewCount: 234, priceEstimate: 1500, distanceKm: 2.3, isAvailable: true, specializations: ['wiring', 'switchgear'], whyChosen: 'Top rated in your area with 98% on-time record', scores: ProviderScores(overall: 94, ratingScore: 96, experience: 88, responseTime: 95, completion: 98, certified: 100, priceValue: 82), responseMinutes: 8, jobsCompleted: 1247, isCertified: true),
      const ServiceProvider(id: 'e2', name: 'Zahid Electrical Works', serviceType: 'electrician', city: 'Karachi', zone: 'Gulshan-e-Iqbal', rating: 4.6, reviewCount: 187, priceEstimate: 1200, distanceKm: 3.1, isAvailable: true, specializations: ['inverter', 'generator'], whyChosen: 'Best value — 20% lower rates with strong reviews', scores: ProviderScores(overall: 86, ratingScore: 92, experience: 78, responseTime: 85, completion: 91, certified: 0, priceValue: 95), responseMinutes: 12, jobsCompleted: 856),
      const ServiceProvider(id: 'e3', name: 'PowerFix Solutions', serviceType: 'electrician', city: 'Lahore', zone: 'Gulberg III', rating: 4.9, reviewCount: 312, priceEstimate: 1800, distanceKm: 1.5, isAvailable: true, specializations: ['smart home', 'solar'], whyChosen: 'Premium quality — specializes in smart installations', scores: ProviderScores(overall: 91, ratingScore: 98, experience: 92, responseTime: 90, completion: 96, certified: 100, priceValue: 70), responseMinutes: 10, jobsCompleted: 2034, isCertified: true),
    ],
    'plumber': [
      const ServiceProvider(id: 'p1', name: 'Master Plumber Karachi', serviceType: 'plumber', city: 'Karachi', zone: 'Clifton', rating: 4.7, reviewCount: 198, priceEstimate: 1000, distanceKm: 1.8, isAvailable: true, specializations: ['pipe fitting', 'drainage'], whyChosen: 'Fastest response time in Clifton area', scores: ProviderScores(overall: 89, ratingScore: 94, experience: 82, responseTime: 97, completion: 93, certified: 100, priceValue: 88), responseMinutes: 6, jobsCompleted: 978, isCertified: true),
      const ServiceProvider(id: 'p2', name: 'Ali Plumbing Services', serviceType: 'plumber', city: 'Lahore', zone: 'Johar Town', rating: 4.5, reviewCount: 156, priceEstimate: 800, distanceKm: 2.5, isAvailable: true, specializations: ['bathroom', 'kitchen'], whyChosen: 'Budget-friendly with bathroom expertise', scores: ProviderScores(overall: 81, ratingScore: 90, experience: 72, responseTime: 80, completion: 85, certified: 0, priceValue: 96), responseMinutes: 15, jobsCompleted: 634),
      const ServiceProvider(id: 'p3', name: 'AquaFix Pro', serviceType: 'plumber', city: 'Islamabad', zone: 'F-8', rating: 4.8, reviewCount: 267, priceEstimate: 1300, distanceKm: 3.0, isAvailable: true, specializations: ['water heater', 'filtration'], whyChosen: 'Top pick for water system specialists', scores: ProviderScores(overall: 88, ratingScore: 96, experience: 85, responseTime: 84, completion: 94, certified: 100, priceValue: 78), responseMinutes: 11, jobsCompleted: 1456, isCertified: true),
    ],
    'cleaner': [
      const ServiceProvider(id: 'c1', name: 'CleanPak Services', serviceType: 'cleaner', city: 'Lahore', zone: 'Model Town', rating: 4.6, reviewCount: 145, priceEstimate: 2500, distanceKm: 2.0, isAvailable: true, specializations: ['deep clean', 'office'], whyChosen: 'Best rated deep cleaning crew in Model Town', scores: ProviderScores(overall: 87, ratingScore: 92, experience: 80, responseTime: 88, completion: 90, certified: 100, priceValue: 75), responseMinutes: 14, jobsCompleted: 723, isCertified: true),
      const ServiceProvider(id: 'c2', name: 'Sparkle Home', serviceType: 'cleaner', city: 'Karachi', zone: 'DHA Phase 5', rating: 4.4, reviewCount: 98, priceEstimate: 2000, distanceKm: 1.2, isAvailable: true, specializations: ['residential', 'move-in'], whyChosen: 'Nearest crew available now — 15 min away', scores: ProviderScores(overall: 79, ratingScore: 88, experience: 68, responseTime: 92, completion: 82, certified: 0, priceValue: 90), responseMinutes: 9, jobsCompleted: 412),
      const ServiceProvider(id: 'c3', name: 'Fresh & Clean Islamabad', serviceType: 'cleaner', city: 'Islamabad', zone: 'G-11', rating: 4.7, reviewCount: 201, priceEstimate: 2800, distanceKm: 4.1, isAvailable: true, specializations: ['sanitization', 'carpet'], whyChosen: 'Premium sanitization with eco-friendly products', scores: ProviderScores(overall: 85, ratingScore: 94, experience: 83, responseTime: 76, completion: 91, certified: 100, priceValue: 72), responseMinutes: 18, jobsCompleted: 1089, isCertified: true),
    ],
    'ac_repair': [
      const ServiceProvider(id: 'a1', name: 'Usman AC & Cooling', serviceType: 'ac_repair', city: 'Karachi', zone: 'Nazimabad', rating: 4.9, reviewCount: 342, priceEstimate: 2000, distanceKm: 1.7, isAvailable: true, specializations: ['split AC', 'inverter'], whyChosen: 'Highest rated AC specialist — inverter expert', scores: ProviderScores(overall: 96, ratingScore: 98, experience: 94, responseTime: 93, completion: 99, certified: 100, priceValue: 80), responseMinutes: 7, jobsCompleted: 2156, isCertified: true),
      const ServiceProvider(id: 'a2', name: 'CoolBreeze Tech', serviceType: 'ac_repair', city: 'Lahore', zone: 'DHA Phase 4', rating: 4.6, reviewCount: 178, priceEstimate: 1500, distanceKm: 2.8, isAvailable: true, specializations: ['window AC', 'servicing'], whyChosen: 'Quick turnaround — same-day service guaranteed', scores: ProviderScores(overall: 83, ratingScore: 92, experience: 76, responseTime: 88, completion: 87, certified: 0, priceValue: 93), responseMinutes: 10, jobsCompleted: 945),
      const ServiceProvider(id: 'a3', name: 'Arctic Repairs', serviceType: 'ac_repair', city: 'Islamabad', zone: 'Blue Area', rating: 4.7, reviewCount: 223, priceEstimate: 1800, distanceKm: 3.5, isAvailable: true, specializations: ['central AC', 'chiller'], whyChosen: 'Commercial & residential — handles all AC types', scores: ProviderScores(overall: 87, ratingScore: 94, experience: 86, responseTime: 82, completion: 92, certified: 100, priceValue: 76), responseMinutes: 13, jobsCompleted: 1378, isCertified: true),
    ],
  };

  static String _detectService(String input) {
    final lower = input.toLowerCase();
    for (final entry in _serviceKeywords.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) return entry.key;
      }
    }
    return 'electrician';
  }

  static String _detectCity(String input) {
    final lower = input.toLowerCase();
    for (final entry in _cityKeywords.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) return entry.key;
      }
    }
    return 'Karachi';
  }

  static bool _isUrdu(String text) {
    return RegExp(r'[؀-ۿ]').hasMatch(text);
  }

  static bool _isRomanUrdu(String text) {
    final lower = text.toLowerCase();
    final romanUrduWords = ['mujhe', 'chahiye', 'bhai', 'karna', 'hai', 'mein', 'abhi', 'acha', 'wala', 'karwani'];
    return romanUrduWords.any((w) => lower.contains(w));
  }

  static String _generateResponse(String input, String service, String city) {
    final sLabel = {
      'electrician': 'electrician',
      'plumber': 'plumber',
      'cleaner': 'cleaning service',
      'ac_repair': 'AC technician',
      'painter': 'painter',
      'carpenter': 'carpenter',
    }[service] ?? service;

    if (_isUrdu(input)) {
      return 'میں نے $city میں آپ کے لیے بہترین $sLabel تلاش کیے ہیں۔ یہ رہے ٹاپ 3 نتائج:';
    }
    if (_isRomanUrdu(input)) {
      return 'Maine $city mein aap ke liye 3 behtareen $sLabel dhundh liye hain. Yeh rahi list — apna pasandida chunein:';
    }
    return "I've found the top 3 ${sLabel}s in $city for you. Pick the one that works best:";
  }

  static Future<AiResponse> processQuery(String input) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final service = _detectService(input);
    final city = _detectCity(input);
    final now = DateTime.now();

    final bookingRef = 'HMZ-${now.millisecondsSinceEpoch.toRadixString(16).substring(4).toUpperCase()}';
    final trace = [
      AgentStep(agent: 'IntentAgent', action: 'Parse Request', detail: 'Detected service="$service", city="$city" from multilingual input', timestamp: now),
      AgentStep(agent: 'DiscoveryAgent', action: 'Search Providers', detail: 'Found ${_providerPool[service]?.length ?? 0} providers for $service in $city zone', timestamp: now.add(const Duration(milliseconds: 300))),
      AgentStep(agent: 'RankAgent', action: 'Rank by Score', detail: 'Weighted: distance(20%) + rating(25%) + reliability(20%) + specialization(15%) + price(10%) + cancellation(10%)', timestamp: now.add(const Duration(milliseconds: 600))),
      AgentStep(agent: 'PriceAgent', action: 'Estimate Cost', detail: 'Applied base + urgency + distance modifiers for each provider', timestamp: now.add(const Duration(milliseconds: 900))),
      AgentStep(agent: 'BookingAgent', action: 'Confirm Booking', detail: 'Slot confirmed for top provider. Ref: $bookingRef. No double-booking conflict.', timestamp: now.add(const Duration(milliseconds: 1100))),
      AgentStep(agent: 'FollowupAgent', action: 'Schedule Reminder', detail: 'WhatsApp reminder scheduled 1hr before appointment. Ref: $bookingRef', timestamp: now.add(const Duration(milliseconds: 1300))),
    ];

    final pool = _providerPool[service] ?? _providerPool['electrician']!;
    final providers = List<ServiceProvider>.from(pool)..shuffle(_rng);
    final top3 = providers.take(3).toList();

    return AiResponse(
      message: _generateResponse(input, service, city),
      detectedService: service,
      detectedCity: city,
      providers: top3,
      trace: trace,
    );
  }
}
