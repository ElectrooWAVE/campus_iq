import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt =
      'You are CampusIQ Assistant, a friendly AI for college students. '
      'Help with study tips, time management, academic concepts, and college life. '
      'For college-specific data like timetables or deadlines, tell students to '
      'check the Home or Schedule tab in the app. Be concise and supportive.';

  String get _apiKey {
    final key = dotenv.env['GROQ_API_KEY'] ?? '';
    if (key.isEmpty) throw Exception('GROQ_API_KEY not found in .env');
    return key;
  }

  /// Main chat method — Groq only, no RAG.
  Future<String> chat(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    final key = _apiKey;

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      // Keep last 6 messages max for context window
      ...history.length > 6
          ? history.sublist(history.length - 6)
          : history,
      {'role': 'user', 'content': userMessage},
    ];

    debugPrint('[Groq] Sending request with ${messages.length} messages...');

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'max_tokens': 1024,
            'temperature': 0.7,
          }),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception(
              'Request timed out. Please check your connection.'),
        );

    debugPrint('[Groq] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      return content.trim();
    } else if (response.statusCode == 401) {
      throw Exception('Invalid Groq API key');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit reached. Please wait a moment and try again.');
    } else {
      debugPrint('[Groq] Error body: ${response.body}');
      throw Exception('Groq API error (${response.statusCode})');
    }
  }

  // Backward compat shim
  Future<String> chatWithGroq(
    String userMessage,
    String context,
    List<Map<String, String>> history,
  ) =>
      chat(userMessage, history);
}
