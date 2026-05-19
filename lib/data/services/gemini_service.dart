import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  /// Embeds text using Gemini embedding-001 via v1 endpoint.
  /// Returns a 768-dimensional vector.
  Future<List<double>> embedText(String text) async {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) throw Exception('GEMINI_API_KEY not set');

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

  /// Direct Gemini chat (used as fallback when RAG has no context).
  Future<String> chatWithGemini(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) throw Exception('GEMINI_API_KEY not set');

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key',
    );

    // Build Gemini-format history
    final contents = <Map<String, dynamic>>[];
    for (final msg in history.take(6)) {
      contents.add({
        'role': msg['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': msg['content']}],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [{
            'text':
                'You are CampusIQ, a helpful AI assistant for college students. '
                'Help students with general college life questions, study tips, '
                'time management, and academic advice. Be friendly and concise. '
                'For college-specific data (timetables, deadlines, announcements), '
                'tell them to check their Home or Schedule tab in the app.'
          }]
        },
        'contents': contents,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else {
      debugPrint('Gemini chat error: ${response.body}');
      throw Exception('Gemini chat failed: ${response.statusCode}');
    }
  }
}
