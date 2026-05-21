import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/provider.dart';
import 'mock_ai_service.dart';

class ApiConfig {
  // Override at build time: flutter run --dart-define=BACKEND_URL=http://192.168.x.x:8000
  static const _override = String.fromEnvironment('BACKEND_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000'; // Android emulator → host machine
  }
}

class ApiResponse {
  final String message;
  final String? detectedService;
  final String? detectedCity;
  final List<ServiceProvider> providers;
  final List<AgentStep> trace;
  final Map<String, dynamic>? booking;
  final bool success;

  const ApiResponse({
    required this.message,
    this.detectedService,
    this.detectedCity,
    required this.providers,
    required this.trace,
    this.booking,
    this.success = true,
  });
}

class ApiService {
  static Future<ApiResponse> chat(String text, {String userId = 'demo_user'}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/chat');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'user_id': userId}),
    ).timeout(const Duration(seconds: 15));

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Unknown error');
    }

    final intent = body['intent'] as Map<String, dynamic>? ?? {};
    final rankedRaw = body['ranked_providers'] as List<dynamic>? ?? [];
    final traceRaw = body['agent_trace'] as List<dynamic>? ?? [];
    final bookingData = body['booking'] as Map<String, dynamic>?;

    final totalPrice = bookingData?['price'] as int? ?? 0;

    final providers = rankedRaw.map((p) {
      final m = p as Map<String, dynamic>;
      final score = (m['score'] as num?)?.toDouble() ?? 0.5;
      return ServiceProvider(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? 'Provider',
        serviceType: intent['service_type'] as String? ?? '',
        city: intent['zone'] as String? ?? 'Karachi',
        zone: intent['zone'] as String? ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 4.0,
        reviewCount: ((m['rating'] as num?)?.toDouble() ?? 4.0 * 50).round(),
        priceEstimate: totalPrice > 0 ? totalPrice : (score * 3000).round(),
        distanceKm: 3.0,
        isAvailable: true,
        specializations: const [],
        whyChosen: 'AI Score: ${score.toStringAsFixed(2)} — best match for your request',
      );
    }).toList();

    final trace = traceRaw.map((t) {
      final m = t as Map<String, dynamic>;
      final agent = m['agent'] as String? ?? 'Agent';
      final step = m['step'] as String? ?? '';
      final reasoning = m['reasoning'] as String? ?? '';
      final ts = m['timestamp'] as String?;
      return AgentStep(
        agent: _mapAgentName(agent, step),
        action: _mapStepAction(step),
        detail: reasoning,
        timestamp: ts != null ? (DateTime.tryParse(ts) ?? DateTime.now()) : DateTime.now(),
      );
    }).toList();

    return ApiResponse(
      message: _cleanResponse(body['response'] as String? ?? 'No response'),
      detectedService: intent['service_type'] as String?,
      detectedCity: intent['zone'] as String?,
      providers: providers,
      trace: trace,
      booking: bookingData,
      success: true,
    );
  }

  static String _cleanResponse(String raw) {
    // Strip raw Gemini function-call markup that leaks into the response text
    var cleaned = raw.replaceAll(RegExp(r'<function=[^>]*>[\s\S]*?</function>', caseSensitive: false), '');
    // Remove dangling transition words left before a stripped function block
    cleaned = cleaned.replaceAll(RegExp(r'\bNext,\s*$', multiLine: true), '');
    return cleaned.trim();
  }

  static String _mapAgentName(String agent, String step) {
    if (agent == 'ADK_Orchestrator') {
      if (step.contains('parse_intent')) return 'IntentAgent';
      if (step.contains('discover')) return 'DiscoveryAgent';
      if (step.contains('rank')) return 'RankAgent';
      if (step.contains('calculate_price')) return 'PriceAgent';
      if (step.contains('create_booking')) return 'BookingAgent';
      if (step.contains('schedule_followup')) return 'FollowupAgent';
      return 'ADK_Orchestrator';
    }
    return agent;
  }

  static String _mapStepAction(String step) {
    if (step.startsWith('tool_call:')) return 'Tool: ${step.substring(10)}';
    if (step.isEmpty) return 'Processing';
    final cleaned = step.replaceAll('_', ' ');
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}
