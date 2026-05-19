import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deadline_model.dart';

class DeadlineRepository {
  final _client = Supabase.instance.client;

  Future<List<DeadlineModel>> getAll({int? year, String? branch}) async {
    var query = _client
        .from('deadlines')
        .select();

    if (year != null) {
      query = query.eq('year', year);
    }
    if (branch != null && branch.isNotEmpty) {
      query = query.eq('branch', branch);
    }

    final data = await query.order('due_date', ascending: true);
    return (data as List).map((e) => DeadlineModel.fromJson(e)).toList();
  }

  Future<List<DeadlineModel>> getUpcoming(String branch, int year, {int limit = 3}) async {
    final now = DateTime.now().toIso8601String();
    final data = await _client
        .from('deadlines')
        .select()
        .eq('branch', branch)
        .eq('year', year)
        .gte('due_date', now)
        .order('due_date', ascending: true)
        .limit(limit);
    return (data as List).map((e) => DeadlineModel.fromJson(e)).toList();
  }

  Future<DeadlineModel> insert(Map<String, dynamic> payload) async {
    final data = await _client
        .from('deadlines')
        .insert(payload)
        .select()
        .single();
    return DeadlineModel.fromJson(data);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _client.from('deadlines').update(payload).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('deadlines').delete().eq('id', id);
  }
}
