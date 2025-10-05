// WHY: Centralize AI backend URL per platform and simple client
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

class AIServiceResponse {
  final String category;
  final double? amount;
  final String? description;
  final String? date;
  final String method; // 'ai' ou 'regex'
  final double? confidence;

  AIServiceResponse({
    required this.category,
    required this.method,
    this.amount,
    this.description,
    this.date,
    this.confidence,
  });
}

class AIService {
  AIService._();
  static final instance = AIService._();

  String get baseUrl {
    // Allow override via --dart-define=AI_BASE_URL=...
    const override = String.fromEnvironment('AI_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) return 'http://127.0.0.1:5001';
    try {
      if (Platform.isAndroid)
        return 'http://10.0.2.2:5001'; // Android emulator -> host
    } catch (_) {}
    return 'http://127.0.0.1:5001';
  }

  Future<bool> health() async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/healthz'))
          .timeout(const Duration(seconds: 3));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<AIServiceResponse?> categorize(String text) async {
    try {
      final r = await http
          .post(
            Uri.parse('$baseUrl/categorize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 6));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        return AIServiceResponse(
          category: (data['category'] ?? 'outros') as String,
          method: (data['method'] ?? 'regex') as String,
          amount: (data['amount'] is num)
              ? (data['amount'] as num).toDouble()
              : null,
          description: data['description'] as String?,
          date: data['date'] as String?,
          confidence: (data['confidence'] is num)
              ? (data['confidence'] as num).toDouble()
              : null,
        );
      }
    } catch (_) {}
    return null;
  }
}
