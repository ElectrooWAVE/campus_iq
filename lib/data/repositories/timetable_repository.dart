import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timetable_model.dart';

class TimetableRepository {
  final _client = Supabase.instance.client;

  Future<List<TimetableModel>> getAll({int? year, String? branch}) async {
    var query = _client.from('timetable_entries').select();
    if (year != null) query = query.eq('year', year);
    if (branch != null && branch.isNotEmpty) query = query.eq('branch', branch);
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => TimetableModel.fromJson(e)).toList();
  }

  Future<List<TimetableModel>> getByBranchYear(String branch, int year) async {
    final data = await _client
        .from('timetable_entries')
        .select()
        .eq('branch', branch)
        .eq('year', year)
        .order('effective_date', ascending: false);
    return (data as List).map((e) => TimetableModel.fromJson(e)).toList();
  }

  /// Returns the latest timetable for a branch+year.
  /// If none found for that specific branch+year, returns the globally latest one.
  Future<TimetableModel?> getLatest(String branch, int year) async {
    // Try exact match first
    final exact = await _client
        .from('timetable_entries')
        .select()
        .eq('branch', branch)
        .eq('year', year)
        .order('effective_date', ascending: false)
        .limit(1);
    if ((exact as List).isNotEmpty) return TimetableModel.fromJson(exact.first);

    // Fallback: just get the globally latest timetable
    final any = await _client
        .from('timetable_entries')
        .select()
        .order('effective_date', ascending: false)
        .limit(1);
    if ((any as List).isEmpty) return null;
    return TimetableModel.fromJson(any.first);
  }

  Future<TimetableModel> insert(Map<String, dynamic> payload) async {
    final data = await _client
        .from('timetable_entries')
        .insert(payload)
        .select()
        .single();
    return TimetableModel.fromJson(data);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _client.from('timetable_entries').update(payload).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('timetable_entries').delete().eq('id', id);
  }
}
