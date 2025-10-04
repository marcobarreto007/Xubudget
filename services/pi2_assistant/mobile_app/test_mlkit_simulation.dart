// Simulated ML Kit OCR test with Canadian receipt text
import 'dart:math';
import 'lib/services/expense_parser.dart';

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
Coffee Large            1      $2.50
Donut Chocolate         1      $1.25
Sandwich Turkey         1      $4.95
Muffin Blueberry        1      $2.75

Subtotal:              $11.45
Tax (13%):             $1.49
Total:                 $12.94

Payment: Credit Card
Thank you for your visit!
''';

  print('Simulated Canadian Receipt Text:');
  print('=' * 50);
  print(simulatedReceiptText);
  print('=' * 50);
  
  try {
    // Test expense parsing
    print('\n=== EXPENSE PARSING TEST ===');
    final parser = ExpenseParser();
    final parsedData = await parser.parseWithAI(simulatedReceiptText);
    
    print('Parsed Results:');
    print('  Description: ${parsedData.description ?? "NOT FOUND"}');
    print('  Amount: ${parsedData.amount ?? "NOT FOUND"}');
    print('  Date: ${parsedData.date ?? "NOT FOUND"}');
    print('  Category: ${parsedData.category ?? "NOT FOUND"}');
    print('  Method: ${parsedData.method ?? "NOT FOUND"}');
    print('  Confidence: ${parsedData.confidence ?? "N/A"}');
    
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

void analyzeAccuracy(String extractedText, ParsedExpenseData parsedData) {
  print('ML Kit OCR Analysis:');
  
  // Check for common Canadian receipt elements
  final hasAmount = parsedData.amount != null;
  final hasDate = parsedData.date != null;
  final hasDescription = parsedData.description != null && parsedData.description!.isNotEmpty;
  
  print('  Amount extracted: ${hasAmount ? "YES" : "NO"}');
  print('  Date extracted: ${hasDate ? "YES" : "NO"}');
  print('  Description extracted: ${hasDescription ? "YES" : "NO"}');
  
  // Check for Canadian-specific patterns
  final hasCanadianCurrency = extractedText.contains('\$') || extractedText.contains('CAD');
  final hasCanadianDate = RegExp(r'\d{1,2}/\d{1,2}/\d{4}').hasMatch(extractedText) ||
                         RegExp(r'\d{1,2}-\d{1,2}-\d{4}').hasMatch(extractedText);
  final hasStoreName = _extractStoreName(extractedText);
  
  print('  Canadian currency detected: ${hasCanadianCurrency ? "YES" : "NO"}');
  print('  Canadian date format detected: ${hasCanadianDate ? "YES" : "NO"}');
  print('  Store name detected: ${hasStoreName != null ? "YES ($hasStoreName)" : "NO"}');
  
  // Check specific data accuracy
  print('\nData Accuracy Check:');
  final expectedAmount = 12.94;
  final expectedStore = 'TIM HORTONS';
  final expectedDate = DateTime(2024, 10, 4);
  
  if (parsedData.amount != null) {
    final amountAccuracy = (1 - (parsedData.amount! - expectedAmount).abs() / expectedAmount) * 100;
    print('  Amount accuracy: ${amountAccuracy.toStringAsFixed(1)}% (expected: \$$expectedAmount, got: \$${parsedData.amount})');
  }
  
  if (parsedData.date != null) {
    final dateAccuracy = parsedData.date!.year == expectedDate.year &&
                        parsedData.date!.month == expectedDate.month &&
                        parsedData.date!.day == expectedDate.day;
    print('  Date accuracy: ${dateAccuracy ? "CORRECT" : "INCORRECT"} (expected: ${expectedDate.toString().split(' ')[0]}, got: ${parsedData.date!.toString().split(' ')[0]})');
  }
  
  if (hasStoreName) {
    final storeAccuracy = hasStoreName!.toUpperCase().contains(expectedStore);
    print('  Store name accuracy: ${storeAccuracy ? "CORRECT" : "PARTIAL"} (expected: $expectedStore, got: $hasStoreName)');
  }
  
  // Overall accuracy score
  final accuracyScore = [
    hasAmount,
    hasDate,
    hasDescription,
    hasCanadianCurrency,
    hasCanadianDate,
    hasStoreName != null
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

void testDifferentFormats() async {
  final parser = ExpenseParser();
  
  // Test 1: Different currency format
  print('\n--- Test 1: Different Currency Format ---');
  final text1 = 'Total: CAD 15.50\nDate: 2024-10-04';
  final result1 = await parser.parseWithAI(text1);
  print('Amount: ${result1.amount}, Date: ${result1.date}');
  
  // Test 2: Different date format
  print('\n--- Test 2: Different Date Format ---');
  final text2 = 'Total: \$25.75\nDate: Oct 4, 2024';
  final result2 = await parser.parseWithAI(text2);
  print('Amount: ${result2.amount}, Date: ${result2.date}');
  
  // Test 3: Blurry/poor quality text
  print('\n--- Test 3: Poor Quality Text ---');
  final text3 = 'T0TAL: \$8.9\nD4TE: 10/04/24\nST0RE: L0BL4WS';
  final result3 = await parser.parseWithAI(text3);
  print('Amount: ${result3.amount}, Date: ${result3.date}, Store: ${result3.description}');
  
  // Test 4: French Canadian receipt
  print('\n--- Test 4: French Canadian Receipt ---');
  final text4 = 'TOTAL: \$18.25\nDATE: 04/10/2024\nMAGASIN: IGA';
  final result4 = await parser.parseWithAI(text4);
  print('Amount: ${result4.amount}, Date: ${result4.date}, Store: ${result4.description}');
}

String? _extractStoreName(String text) {
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
