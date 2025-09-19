// WHY: HTTP client service for communicating with AI categorization backend
import 'dart:convert';
import 'package:http/http.dart' as http;

class CategorizerRequest {
  final String text;

  CategorizerRequest({required this.text});

  Map<String, dynamic> toJson() => {'text': text};
}

class CategorizerResponse {
  final String category;
  final double confidence;
  final String method;
  final String? description;
  final double? amount;
  final String? date;

  CategorizerResponse({
    required this.category,
    required this.confidence,
    required this.method,
    this.description,
    this.amount,
    this.date,
  });

  factory CategorizerResponse.fromJson(Map<String, dynamic> json) {
    return CategorizerResponse(
      category: json['category'] ?? 'outros',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      method: json['method'] ?? 'regex',
      description: json['description'],
      amount: json['amount']?.toDouble(),
      date: json['date'],
    );
  }
}

class CategorizerService {
  static const String _baseUrl = 'http://localhost:5001';
  static const Duration _timeout = Duration(seconds: 5);

  /// Check if the AI categorization service is available
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/healthz'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Categorize expense text using AI service
  Future<CategorizerResponse?> categorizeExpense(String text) async {
    try {
      final request = CategorizerRequest(text: text);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/categorize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CategorizerResponse.fromJson(data);
      }
    } catch (e) {
      // Service not available, caller should use fallback
    }
    
    return null;
  }

  /// Get service health status and information
  Future<Map<String, dynamic>?> getServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/healthz'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Service not available
    }
    
    return null;
  }
}