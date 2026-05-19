import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pdf_note_model.dart';

class NotesRepository {
  final _client = Supabase.instance.client;

  Future<List<PdfNoteModel>> getAll({int? year, String? branch}) async {
    var query = _client
        .from('pdf_notes')
        .select();

    if (year != null) {
      query = query.eq('year', year);
    }
    if (branch != null && branch.isNotEmpty) {
      query = query.eq('branch', branch);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => PdfNoteModel.fromJson(e)).toList();
  }

  Future<List<PdfNoteModel>> getByBranchYear(String branch, int year) async {
    final data = await _client
        .from('pdf_notes')
        .select()
        .eq('branch', branch)
        .eq('year', year)
        .order('created_at', ascending: false);
    return (data as List).map((e) => PdfNoteModel.fromJson(e)).toList();
  }

  Future<PdfNoteModel> insert(Map<String, dynamic> payload) async {
    final data = await _client
        .from('pdf_notes')
        .insert(payload)
        .select()
        .single();
    return PdfNoteModel.fromJson(data);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _client.from('pdf_notes').update(payload).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('pdf_notes').delete().eq('id', id);
  }
}
