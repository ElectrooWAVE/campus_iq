import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  Future<String> chatWithGroq(
    String userMessage,
    String context,
    List<Map<String, String>> history,
  ) async {
    final key = dotenv.env['GROQ_API_KEY']!;
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final systemPrompt = '''You are CampusIQ, a college assistant for students.
Answer ONLY based on the verified college information provided below.
If the answer is not found in the context, respond exactly:
"I don't have that information. Please contact your department office directly."
Do not use any outside knowledge. Be concise, friendly, and helpful.
Do not make up timetables, dates, or policies.

Verified College Information:
$context''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.take(5).toList(),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['choices'][0]['message']['content'] as String;
    } else {
      debugPrint('Groq error: ${response.body}');
      throw Exception('Groq chat failed: ${response.statusCode}');
    }
  }
}
