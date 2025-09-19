// WHY: OCR service for extracting text from images using ML Kit
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  late final TextRecognizer _textRecognizer;

  OCRService() {
    _textRecognizer = TextRecognizer();
  }

  /// Extract text from image file using ML Kit
  Future<String?> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isNotEmpty) {
        return recognizedText.text;
      }
      return null;
    } catch (e) {
      throw Exception('Error during OCR processing: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}