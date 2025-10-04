// Test ML Kit OCR with Canadian receipt
import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'lib/services/expense_parser.dart';

void main() async {
  print('=== ML KIT OCR TEST WITH CANADIAN RECEIPT ===');
  
  // Test with Canadian receipt image
  final testImagePath = 'test_receipt_canada.jpg';
  
  if (!await File(testImagePath).exists()) {
    print('ERROR: Test image not found at $testImagePath');
    print('Please place a Canadian grocery receipt image at this location');
    return;
  }
  
  try {
    // Initialize OCR service
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFile(File(testImagePath));
    
    print('Processing image with ML Kit...');
    final recognizedText = await textRecognizer.processImage(inputImage);
    
    if (recognizedText.text.isEmpty) {
      print('ERROR: No text recognized from image');
      return;
    }
    
    print('\n=== EXTRACTED TEXT ===');
    print(recognizedText.text);
    print('\n=== TEXT LENGTH: ${recognizedText.text.length} characters ===');
    
    // Test expense parsing
    print('\n=== EXPENSE PARSING TEST ===');
    final parser = ExpenseParser();
    final parsedData = await parser.parseWithAI(recognizedText.text);
    
    print('Parsed Results:');
    print('  Description: ${parsedData.description ?? "NOT FOUND"}');
    print('  Amount: ${parsedData.amount ?? "NOT FOUND"}');
    print('  Date: ${parsedData.date ?? "NOT FOUND"}');
    print('  Category: ${parsedData.category ?? "NOT FOUND"}');
    print('  Method: ${parsedData.method ?? "NOT FOUND"}');
    print('  Confidence: ${parsedData.confidence ?? "N/A"}');
    
    // Analyze accuracy
    print('\n=== ACCURACY ANALYSIS ===');
    analyzeAccuracy(recognizedText.text, parsedData);
    
    // Clean up
    textRecognizer.close();
    
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

String? _extractStoreName(String text) {
  final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
  
  // Look for store name in first few lines (usually at top)
  for (int i = 0; i < math.min(5, lines.length); i++) {
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
