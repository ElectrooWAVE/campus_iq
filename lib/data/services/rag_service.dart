import 'package:supabase_flutter/supabase_flutter.dart';
import 'gemini_service.dart';
import '../models/knowledge_doc_model.dart';

class RagService {
  final _gemini = GeminiService();
  final _client = Supabase.instance.client;

  /// Performs RAG search: embed query → pgvector match → return context string.
  /// Returns null if no documents found (caller must show fallback).
  Future<String?> retrieveContext({
    required String query,
    required String branch,
    required int year,
    double threshold = 0.7,
    int count = 3,
  }) async {
    final embedding = await _gemini.embedText(query);

    final result = await _client.rpc(
      'match_documents',
      params: {
        'query_embedding': embedding,
        'match_threshold': threshold,
        'match_count': count,
        'filter_branch': branch,
        'filter_year': year,
      },
    );

    if (result == null || (result as List).isEmpty) return null;

    final docs = result
        .map((r) => r['content'] as String)
        .toList();

    return docs.join('\n\n---\n\n');
  }
}
