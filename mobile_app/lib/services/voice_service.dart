// WHY: Voice service for speech-to-text transcription using speech_to_text package
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  late stt.SpeechToText _speech;
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';

  VoiceService() {
    _speech = stt.SpeechToText();
  }

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print('Error initializing speech: $e');
      return false;
    }
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized && _speech.isAvailable;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get the last transcribed words
  String get lastWords => _lastWords;

  /// Start listening for speech input
  Future<bool> startListening({
    required Function(String) onResult,
    String localeId = 'pt_BR',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!isAvailable) {
      return false;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          onResult(_lastWords);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      
      _isListening = true;
      return true;
    } catch (e) {
      print('Error starting to listen: $e');
      return false;
    }
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Cancel current listening session
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      _lastWords = '';
    }
  }

  /// Get available locales for speech recognition
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!isAvailable) {
      return [];
    }

    try {
      final locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      print('Error getting locales: $e');
      return [];
    }
  }

  /// Check if a specific locale is supported
  Future<bool> isLocaleSupported(String localeId) async {
    final availableLocales = await getAvailableLocales();
    return availableLocales.contains(localeId);
  }

  /// Clean up resources
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _isInitialized = false;
    _isListening = false;
    _lastWords = '';
  }
}