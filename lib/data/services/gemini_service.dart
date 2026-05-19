import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  /// Embeds text using Gemini embedding-001 via v1 endpoint (NOT v1beta).
  /// Returns a 768-dimensional vector.
  Future<List<double>> embedText(String text) async {
    final key = dotenv.env['GEMINI_API_KEY']!;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/embedding-001:embedContent?key=$key',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'models/embedding-001',
        'content': {
          'parts': [
            {'text': text}
          ]
        },
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final values = data['embedding']['values'] as List;
      return values.map((e) => (e as num).toDouble()).toList();
    } else {
      debugPrint('Gemini embedding error: ${response.body}');
      throw Exception('Gemini embedding failed: ${response.statusCode}');
    }
  }
}
