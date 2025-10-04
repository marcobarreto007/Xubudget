// WHY: Expense parser for extracting expense data from text using regex patterns for PT-BR
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class ParsedExpenseData {
  final String? description;
  final double? amount;
  final DateTime? date;
  final String? category;
  final String? method; // 'ai' ou 'regex'
  final double? confidence;

  ParsedExpenseData(
      {this.description,
      this.amount,
      this.date,
      this.category,
      this.method,
      this.confidence});
}

class ExpenseParser {
  // Resolved via AIService per-platform

  /// Parse expense data from text using AI service if available, fallback to regex
  Future<ParsedExpenseData> parseWithAI(String text) async {
    try {
      // Try AI categorization first
      final aiResult = await _tryAICategorization(text);
      if (aiResult != null) {
        return aiResult;
      }
    } catch (e) {
      // Fallback to regex parsing if AI service is not available
    }

    return _parseWithRegex(text);
  }

  /// Try to categorize using AI service
  Future<ParsedExpenseData?> _tryAICategorization(String text) async {
    try {
      final response = await AIService.instance.categorize(text);
      if (response != null) {
        return ParsedExpenseData(
          description: response.description,
          amount: response.amount,
          date:
              response.date != null ? DateTime.tryParse(response.date!) : null,
          category: response.category,
          method: response.method,
          confidence: response.confidence,
        );
      }
    } catch (e) {
      // AI service not available, continue with regex
    }
    return null;
  }

  /// Parse expense data using regex patterns for Portuguese text
  ParsedExpenseData _parseWithRegex(String text) {
    final cleanText = text.toLowerCase().trim();

    // Extract amount using various patterns for Brazilian currency
    double? amount = _extractAmount(cleanText);

    // Extract date
    DateTime? date = _extractDate(cleanText);

    // Extract description (simplified - use first meaningful line)
    String? description = _extractDescription(text);

    // Determine category based on keywords
    String? category = _categorizeByKeywords(cleanText);

    return ParsedExpenseData(
      description: description,
      amount: amount,
      date: date,
      category: category,
      method: 'regex',
      confidence: null,
    );
  }

  double? _extractAmount(String text) {
    // Pattern for Brazilian currency format (R$ 12,34 or 12,34)
    final patterns = [
      RegExp(r'r\$\s*(\d{1,3}(?:\.\d{3})*),(\d{2})'),
      RegExp(r'(\d{1,3}(?:\.\d{3})*),(\d{2})\s*r\$'),
      RegExp(r'(\d{1,3}(?:\.\d{3})*),(\d{2})'),
      RegExp(r'(\d+),(\d{2})'),
      RegExp(r'(\d+)\.(\d{2})'), // Fallback for dot decimal
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final integerPart = match.group(1)?.replaceAll('.', '') ?? '0';
        final decimalPart = match.group(2) ?? '00';
        return double.tryParse('$integerPart.$decimalPart');
      }
    }
    return null;
  }

  DateTime? _extractDate(String text) {
    // Pattern for Brazilian date format (dd/mm/yyyy or dd/mm/yy)
    final patterns = [
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final day = int.tryParse(match.group(1) ?? '') ?? 1;
        final month = int.tryParse(match.group(2) ?? '') ?? 1;
        var year = int.tryParse(match.group(3) ?? '') ?? DateTime.now().year;

        // Convert 2-digit year to 4-digit
        if (year < 100) {
          year += (year < 50) ? 2000 : 1900;
        }

        try {
          return DateTime(year, month, day);
        } catch (e) {
          // Invalid date
        }
      }
    }
    return null;
  }

  String? _extractDescription(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final line in lines) {
      // Skip lines that are just numbers or currency
      if (RegExp(r'^[\d\s\.,R\$]*$').hasMatch(line)) continue;

      // Skip very short lines
      if (line.length < 3) continue;

      // Return first meaningful line
      return line;
    }

    return lines.isNotEmpty ? lines.first : null;
  }

  String? _categorizeByKeywords(String text) {
    final categories = {
      'food': [
        'market', 'mercado', 'super', 'padaria', 'restaurante', 'lanche', 'comida', 'food', 'cafe', 'pizza',
        'grocery', 'supermarket', 'dining', 'lunch', 'dinner', 'breakfast', 'snack', 'alimentacao'
      ],
      'transport': [
        'uber', 'taxi', 'posto', 'combustivel', 'gasolina', 'onibus', 'metro', 'gas', 'fuel',
        'car', 'bus', 'subway', 'transportation', 'transporte', 'vehicle', 'maintenance'
      ],
      'health': [
        'farmacia', 'hospital', 'medico', 'clinica', 'consulta', 'exame', 'medicina', 'pharmacy',
        'health', 'medical', 'medicine', 'saude', 'clinic', 'doctor'
      ],
      'housing': [
        'casa', 'aluguel', 'condominio', 'rent', 'housing', 'apartamento', 'apartment', 'house',
        'mortgage', 'property', 'home', 'moradia'
      ],
      'utilities': [
        'luz', 'agua', 'gas', 'internet', 'telefone', 'electricity', 'water', 'phone', 'internet',
        'utilities', 'bills', 'energy', 'utilities'
      ],
      'shopping': [
        'compras', 'loja', 'shopping', 'roupa', 'clothes', 'store', 'retail',
        'personal', 'items', 'goods', 'merchandise'
      ],
      'entertainment': [
        'cinema', 'teatro', 'bar', 'festa', 'viagem', 'hotel', 'entretenimento', 'jogo',
        'movie', 'theater', 'party', 'game', 'netflix', 'spotify', 'streaming', 'lazer', 'leisure'
      ],
      'education': [
        'escola', 'universidade', 'curso', 'livro', 'material', 'estudo',
        'education', 'learning', 'study', 'course', 'book', 'school', 'university', 'training', 'educacao'
      ],
      'savings': [
        'poupanca', 'investimento', 'savings', 'investment', 'deposito', 'invest',
        'emergency', 'fund', 'retirement', 'pension', 'investimento'
      ],
      'other': [
        'outro', 'diversos', 'misc', 'other', 'varios', 'miscellaneous', 'unknown'
      ],
    };

    for (final entry in categories.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'outros'; // Default category
  }
}
