import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository {
  final _client = Supabase.instance.client;

  Future<List<AnnouncementModel>> getAll({String? priority}) async {
    var query = _client
        .from('announcements')
        .select();

    if (priority != null && priority != 'all') {
      query = query.eq('priority', priority);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => AnnouncementModel.fromJson(e)).toList();
  }

  Future<List<AnnouncementModel>> getPublished(String branch, int year) async {
    final data = await _client
        .from('announcements')
        .select()
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => AnnouncementModel.fromJson(e))
        .where((a) =>
            (a.branch == null || a.branch == branch) &&
            (a.year == null || a.year == year))
        .toList();
  }

  Future<AnnouncementModel?> getLatest(String branch, int year) async {
    final list = await getPublished(branch, year);
    return list.isEmpty ? null : list.first;
  }

  Future<AnnouncementModel> insert(Map<String, dynamic> payload) async {
    final data = await _client
        .from('announcements')
        .insert(payload)
        .select()
        .single();
    return AnnouncementModel.fromJson(data);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _client.from('announcements').update(payload).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('announcements').delete().eq('id', id);
  }

  Future<void> togglePublish(String id, bool published) async {
    await _client
        .from('announcements')
        .update({'is_published': published})
        .eq('id', id);
  }
}
