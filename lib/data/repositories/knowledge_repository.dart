import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/knowledge_doc_model.dart';

class KnowledgeRepository {
  final _client = Supabase.instance.client;

  Future<List<KnowledgeDocModel>> getAll({String? category}) async {
    var query = _client
        .from('knowledge_base_docs')
        .select();

    if (category != null && category != 'all') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => KnowledgeDocModel.fromJson(e)).toList();
  }

  Future<KnowledgeDocModel> insert(Map<String, dynamic> payload) async {
    final data = await _client
        .from('knowledge_base_docs')
        .insert(payload)
        .select()
        .single();
    return KnowledgeDocModel.fromJson(data);
  }

  Future<void> updateEmbedding(String id, List<double> embedding) async {
    await _client
        .from('knowledge_base_docs')
        .update({'embedding': embedding})
        .eq('id', id);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _client.from('knowledge_base_docs').update(payload).eq('id', id);
  }

  Future<void> deleteBySourceId(String sourceId, String sourceType) async {
    await _client
        .from('knowledge_base_docs')
        .delete()
        .eq('source_id', sourceId)
        .eq('source_type', sourceType);
  }

  Future<void> delete(String id) async {
    await _client.from('knowledge_base_docs').delete().eq('id', id);
  }
}
