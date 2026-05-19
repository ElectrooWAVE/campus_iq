import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _systemPrompt = '''You are CampusIQ Assistant, a helpful and friendly AI chatbot for college students.
You help students with:
- General college life questions and advice
- Study tips and academic strategies
- Time management and productivity
- Understanding course concepts
- Career guidance and internship advice
- Campus life questions

Be conversational, concise, and supportive. If asked about very specific college data 
(like their exact timetable, specific deadlines, or announcements), tell them to check the 
Home, Schedule, or Notes tabs in the CampusIQ app where their admin posts that information.

Always respond in a friendly, helpful tone.''';

  Future<String> chat(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GROQ_API_KEY is not configured');
    }

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      // Keep last 6 messages for context
      ...history.skip(history.length > 6 ? history.length - 6 : 0),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      url,
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
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['choices'][0]['message']['content'] as String;
    } else {
      debugPrint('Groq error ${response.statusCode}: ${response.body}');
      throw Exception('Groq API error: ${response.statusCode}');
    }
  }

  // Keep backward compat for old callers
  Future<String> chatWithGroq(
    String userMessage,
    String context,
    List<Map<String, String>> history,
  ) => chat(userMessage, history);
}
