// Simple smoke test for AI connectivity
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' as io;

Future<void> main() async {
  // Mirror baseUrl logic used in AIService
  const isWeb = bool.fromEnvironment('dart.library.html');
  // Allow override via environment variable AI_BASE_URL
  final envOverride = io.Platform.environment['AI_BASE_URL'];
  // We can't check Platform.isAndroid here in a simple script, so default to host
  final baseUrl = (envOverride != null && envOverride.isNotEmpty)
      ? envOverride
      : (isWeb ? 'http://127.0.0.1:5001' : 'http://127.0.0.1:5001');

  print('[AI SMOKE] Base URL: ' + baseUrl);

  // 1) Health check
  try {
    final r = await http
        .get(Uri.parse('$baseUrl/healthz'))
        .timeout(const Duration(seconds: 3));
    print('[AI SMOKE] GET /healthz -> ${r.statusCode} ${r.body}');
  } catch (e) {
    print('[AI SMOKE] GET /healthz FAILED: $e');
  }

  // 2) Root endpoint
  try {
    final r =
        await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 3));
    print(
        '[AI SMOKE] GET / -> ${r.statusCode} ${r.body.substring(0, r.body.length > 200 ? 200 : r.body.length)}');
  } catch (e) {
    print('[AI SMOKE] GET / FAILED: $e');
  }

  // 3) Categorize
  try {
    final body = jsonEncode({'text': 'Uber Aeroporto 38,90 18/09'});
    final r = await http
        .post(
          Uri.parse('$baseUrl/categorize'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 6));
    print('[AI SMOKE] POST /categorize -> ${r.statusCode} ${r.body}');
  } catch (e) {
    print('[AI SMOKE] POST /categorize FAILED: $e');
  }
}
