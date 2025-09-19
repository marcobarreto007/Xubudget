// WHY: Parser for extracting expense data from Portuguese text using regex patterns
import '../models/expense.dart';

class ExpenseParser {
  // Regex patterns for parsing Portuguese expense descriptions
  static final RegExp _amountRegex = RegExp(r'(\d+[,.]?\d*)');
  static final RegExp _dateRegex = RegExp(r'(\d{1,2}[-/]\d{1,2}[-/]?\d{2,4})');
  
  // Category keywords in Portuguese
  static final Map<String, List<String>> _categoryKeywords = {
    'alimentacao': ['mercado', 'supermercado', 'restaurante', 'padaria', 'açougue', 'feira', 'comida', 'lanche'],
    'transporte': ['combustivel', 'gasolina', 'uber', 'taxi', 'onibus', 'metro', 'estacionamento', 'posto'],
    'saude': ['farmacia', 'medico', 'hospital', 'remedio', 'consulta', 'exame'],
    'moradia': ['aluguel', 'condominio', 'agua', 'luz', 'gas', 'internet', 'telefone'],
    'lazer': ['cinema', 'teatro', 'bar', 'festa', 'viagem', 'hotel'],
  };

  ParsedExpense parseText(String text) {
    final cleanText = text.toLowerCase();
    
    // Extract amount
    final amountMatch = _amountRegex.firstMatch(cleanText);
    double? amount;
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)?.replaceAll(',', '.');
      amount = double.tryParse(amountStr ?? '');
    }

    // Extract date
    final dateMatch = _dateRegex.firstMatch(cleanText);
    DateTime? date;
    if (dateMatch != null) {
      // Simple date parsing - can be improved
      date = DateTime.now(); // Default to today for now
    }

    // Determine category
    String category = 'outros';
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (cleanText.contains(keyword)) {
          category = entry.key;
          break;
        }
      }
      if (category != 'outros') break;
    }

    return ParsedExpense(
      description: text.trim(),
      amount: amount,
      date: date,
      category: category,
    );
  }
}

class ParsedExpense {
  final String description;
  final double? amount;
  final DateTime? date;
  final String category;

  ParsedExpense({
    required this.description,
    this.amount,
    this.date,
    required this.category,
  });
}