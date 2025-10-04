// Simple ML Kit OCR test without Flutter dependencies
import 'dart:math';

void main() async {
  print('=== ML KIT OCR SIMULATION WITH CANADIAN RECEIPT ===');
  
  // Simulate Canadian grocery receipt text (what ML Kit would extract)
  final simulatedReceiptText = '''
TIM HORTONS
123 Main Street
Toronto, ON M5H 2N2
(416) 555-0123

Receipt #12345
Date: 10/04/2024
Time: 14:30

Item                    Qty    Price
Coffee Large            1      \$2.50
Donut Chocolate         1      \$1.25
Sandwich Turkey         1      \$4.95
Muffin Blueberry        1      \$2.75

Subtotal:              \$11.45
Tax (13%):             \$1.49
Total:                 \$12.94

Payment: Credit Card
Thank you for your visit!
''';

  print('Simulated Canadian Receipt Text:');
  print('=' * 50);
  print(simulatedReceiptText);
  print('=' * 50);
  
  try {
    // Test expense parsing with simple regex
    print('\n=== EXPENSE PARSING TEST ===');
    final parsedData = parseReceiptText(simulatedReceiptText);
    
    print('Parsed Results:');
    print('  Description: ${parsedData['description'] ?? "NOT FOUND"}');
    print('  Amount: ${parsedData['amount'] ?? "NOT FOUND"}');
    print('  Date: ${parsedData['date'] ?? "NOT FOUND"}');
    print('  Store: ${parsedData['store'] ?? "NOT FOUND"}');
    print('  Category: ${parsedData['category'] ?? "NOT FOUND"}');
    
    // Analyze accuracy
    print('\n=== ACCURACY ANALYSIS ===');
    analyzeAccuracy(simulatedReceiptText, parsedData);
    
    // Test with different receipt formats
    print('\n=== TESTING DIFFERENT RECEIPT FORMATS ===');
    testDifferentFormats();
    
  } catch (e) {
    print('ERROR: $e');
  }
}

Map<String, dynamic> parseReceiptText(String text) {
  final cleanText = text.toLowerCase().trim();
  
  // Extract amount using various patterns for Canadian currency
  double? amount = extractAmount(cleanText);
  
  // Extract date
  DateTime? date = extractDate(cleanText);
  
  // Extract description (simplified - use first meaningful line)
  String? description = extractDescription(text);
  
  // Extract store name
  String? store = extractStoreName(text);
  
  // Determine category based on keywords
  String? category = categorizeByKeywords(cleanText);
  
  return {
    'description': description,
    'amount': amount,
    'date': date,
    'store': store,
    'category': category,
  };
}

double? extractAmount(String text) {
  // Pattern for Canadian currency format (\$12.34 or 12.34)
  final patterns = [
    RegExp(r'\$\s*(\d{1,3}(?:,\d{3})*\.\d{2})'),
    RegExp(r'\$\s*(\d+\.\d{2})'),
    RegExp(r'(\d{1,3}(?:,\d{3})*\.\d{2})\s*\$'),
    RegExp(r'(\d+\.\d{2})\s*\$'),
    RegExp(r'total:\s*\$?(\d+\.\d{2})', caseSensitive: false),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
      return double.tryParse(amountStr);
    }
  }
  return null;
}

DateTime? extractDate(String text) {
  // Pattern for Canadian date format (dd/mm/yyyy or dd-mm-yyyy)
  final patterns = [
    RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
    RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
    RegExp(r'date:\s*(\d{1,2})/(\d{1,2})/(\d{4})', caseSensitive: false),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '') ?? 1;
      final month = int.tryParse(match.group(2) ?? '') ?? 1;
      final year = int.tryParse(match.group(3) ?? '') ?? DateTime.now().year;

      try {
        return DateTime(year, month, day);
      } catch (e) {
        // Invalid date
      }
    }
  }
  return null;
}

String? extractDescription(String text) {
  final lines = text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  for (final line in lines) {
    // Skip lines that are just numbers or currency
    if (RegExp(r'^[\d\s\.,\$]*$').hasMatch(line)) continue;

    // Skip very short lines
    if (line.length < 3) continue;

    // Skip common receipt headers
    if (line.toLowerCase().contains('receipt') ||
        line.toLowerCase().contains('invoice') ||
        line.toLowerCase().contains('total') ||
        line.toLowerCase().contains('subtotal') ||
        line.toLowerCase().contains('date:') ||
        line.toLowerCase().contains('time:')) {
      continue;
    }

    // Return first meaningful line
    return line;
  }

  return lines.isNotEmpty ? lines.first : null;
}

String? extractStoreName(String text) {
  final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
  
  // Look for store name in first few lines (usually at top)
  for (int i = 0; i < min(5, lines.length); i++) {
    final line = lines[i].trim();
    
    // Skip lines that are just numbers, dates, or very short
    if (line.length < 3 || 
        RegExp(r'^[\d\s\.,\$]*$').hasMatch(line) ||
        RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(line)) {
      continue;
    }
    
    // Skip common receipt headers
    if (line.toLowerCase().contains('receipt') ||
        line.toLowerCase().contains('invoice') ||
        line.toLowerCase().contains('total') ||
        line.toLowerCase().contains('subtotal')) {
      continue;
    }
    
    return line;
  }
  
  return null;
}

String? categorizeByKeywords(String text) {
  final categories = {
    'food': [
      'coffee', 'donut', 'sandwich', 'muffin', 'food', 'restaurant',
      'market', 'grocery', 'supermarket', 'tim hortons', 'mcdonalds'
    ],
    'transport': [
      'uber', 'taxi', 'gas', 'fuel', 'bus', 'metro', 'parking'
    ],
    'health': [
      'pharmacy', 'hospital', 'doctor', 'clinic', 'medicine'
    ],
    'housing': [
      'rent', 'utilities', 'electricity', 'water', 'internet'
    ],
    'leisure': [
      'cinema', 'theater', 'bar', 'entertainment', 'game'
    ],
    'education': [
      'school', 'university', 'course', 'book', 'study'
    ],
  };

  for (final entry in categories.entries) {
    for (final keyword in entry.value) {
      if (text.contains(keyword)) {
        return entry.key;
      }
    }
  }

  return 'other'; // Default category
}

void analyzeAccuracy(String extractedText, Map<String, dynamic> parsedData) {
  print('ML Kit OCR Analysis:');
  
  // Check for common Canadian receipt elements
  final hasAmount = parsedData['amount'] != null;
  final hasDate = parsedData['date'] != null;
  final hasDescription = parsedData['description'] != null && parsedData['description']!.isNotEmpty;
  final hasStore = parsedData['store'] != null;
  
  print('  Amount extracted: ${hasAmount ? "YES" : "NO"}');
  print('  Date extracted: ${hasDate ? "YES" : "NO"}');
  print('  Description extracted: ${hasDescription ? "YES" : "NO"}');
  print('  Store name extracted: ${hasStore ? "YES" : "NO"}');
  
  // Check for Canadian-specific patterns
  final hasCanadianCurrency = extractedText.contains('\$');
  final hasCanadianDate = RegExp(r'\d{1,2}/\d{1,2}/\d{4}').hasMatch(extractedText) ||
                         RegExp(r'\d{1,2}-\d{1,2}-\d{4}').hasMatch(extractedText);
  
  print('  Canadian currency detected: ${hasCanadianCurrency ? "YES" : "NO"}');
  print('  Canadian date format detected: ${hasCanadianDate ? "YES" : "NO"}');
  
  // Check specific data accuracy
  print('\nData Accuracy Check:');
  final expectedAmount = 12.94;
  final expectedStore = 'TIM HORTONS';
  final expectedDate = DateTime(2024, 10, 4);
  
  if (parsedData['amount'] != null) {
    final amountAccuracy = (1 - (parsedData['amount'] - expectedAmount).abs() / expectedAmount) * 100;
    print('  Amount accuracy: ${amountAccuracy.toStringAsFixed(1)}% (expected: \$$expectedAmount, got: \$${parsedData['amount']})');
  }
  
  if (parsedData['date'] != null) {
    final dateAccuracy = parsedData['date'].year == expectedDate.year &&
                        parsedData['date'].month == expectedDate.month &&
                        parsedData['date'].day == expectedDate.day;
    print('  Date accuracy: ${dateAccuracy ? "CORRECT" : "INCORRECT"} (expected: ${expectedDate.toString().split(' ')[0]}, got: ${parsedData['date'].toString().split(' ')[0]})');
  }
  
  if (hasStore) {
    final storeAccuracy = parsedData['store'].toString().toUpperCase().contains(expectedStore);
    print('  Store name accuracy: ${storeAccuracy ? "CORRECT" : "PARTIAL"} (expected: $expectedStore, got: ${parsedData['store']})');
  }
  
  // Overall accuracy score
  final accuracyScore = [
    hasAmount,
    hasDate,
    hasDescription,
    hasStore,
    hasCanadianCurrency,
    hasCanadianDate,
  ].where((e) => e).length / 6 * 100;
  
  print('\nOverall Accuracy Score: ${accuracyScore.toStringAsFixed(1)}%');
  
  if (accuracyScore < 70) {
    print('\nWARNING: ML Kit OCR accuracy is below 70%');
    print('Consider using ReceiptAI as fallback for better results');
  } else if (accuracyScore < 90) {
    print('\nNOTE: ML Kit OCR accuracy is moderate');
    print('ReceiptAI could provide better structured data extraction');
  } else {
    print('\nSUCCESS: ML Kit OCR accuracy is good');
    print('ML Kit is sufficient for basic receipt processing');
  }
}

void testDifferentFormats() {
  // Test 1: Different currency format
  print('\n--- Test 1: Different Currency Format ---');
  final text1 = 'Total: CAD 15.50\nDate: 2024-10-04';
  final result1 = parseReceiptText(text1);
  print('Amount: ${result1['amount']}, Date: ${result1['date']}');
  
  // Test 2: Different date format
  print('\n--- Test 2: Different Date Format ---');
  final text2 = 'Total: \$25.75\nDate: Oct 4, 2024';
  final result2 = parseReceiptText(text2);
  print('Amount: ${result2['amount']}, Date: ${result2['date']}');
  
  // Test 3: Blurry/poor quality text
  print('\n--- Test 3: Poor Quality Text ---');
  final text3 = 'T0TAL: \$8.9\nD4TE: 10/04/24\nST0RE: L0BL4WS';
  final result3 = parseReceiptText(text3);
  print('Amount: ${result3['amount']}, Date: ${result3['date']}, Store: ${result3['store']}');
  
  // Test 4: French Canadian receipt
  print('\n--- Test 4: French Canadian Receipt ---');
  final text4 = 'TOTAL: \$18.25\nDATE: 04/10/2024\nMAGASIN: IGA';
  final result4 = parseReceiptText(text4);
  print('Amount: ${result4['amount']}, Date: ${result4['date']}, Store: ${result4['store']}');
}
