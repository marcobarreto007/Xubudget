// WHY: Client for the FastAPI /chat endpoint with simple response typing
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ai_service.dart';

class ChatResponse {
  final String response;
  final String
      intent; // e.g., budget_set, expense_added, budget_status, purchase_advice, general
  final Map<String, dynamic>? data;
  final List<String>? suggestions;
  final String? currency;

  ChatResponse({
    required this.response,
    required this.intent,
    this.data,
    this.suggestions,
    this.currency,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] as String? ?? '',
      intent: json['intent'] as String? ?? 'general',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
      suggestions: (json['suggestions'] is List)
          ? (json['suggestions'] as List).whereType<String>().toList()
          : null,
      currency: json['currency'] as String?,
    );
  }
}

class ChatService {
  ChatService._();
  static final instance = ChatService._();

  Future<ChatResponse?> send({
    required String message,
    String userId = 'web',
    Map<String, dynamic>? conversationContext,
  }) async {
    final baseUrl = AIService.instance.baseUrl;
    final uri = Uri.parse('$baseUrl/chat');
    final body = jsonEncode({
      'message': message,
      'user_id': userId,
      'conversation_context': conversationContext ?? {},
    });
    try {
      final r = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        return ChatResponse.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}
