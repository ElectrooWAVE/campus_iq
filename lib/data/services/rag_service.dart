import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'gemini_service.dart';

class RagService {
  final _gemini = GeminiService();
  final _client = Supabase.instance.client;

  /// Performs RAG search: embed query → pgvector match → return context string.
  /// Returns null if:
  ///   - Embedding fails
  ///   - The match_documents RPC doesn't exist yet
  ///   - No documents are found above threshold
  /// The caller must handle null by using a direct LLM fallback.
  Future<String?> retrieveContext({
    required String query,
    required String branch,
    required int year,
    double threshold = 0.65,
    int count = 3,
  }) async {
    try {
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
    } catch (e) {
      // RPC may not exist yet (match_documents not created in Supabase)
      // or embedding API failed — return null for graceful fallback
      debugPrint('RAG retrieveContext error (non-fatal): $e');
      return null;
    }
  }
}
