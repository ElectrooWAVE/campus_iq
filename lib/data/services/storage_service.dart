import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _client = Supabase.instance.client;

  Future<Map<String, String>> uploadImage(
    String bucket,
    String folder,
    Uint8List bytes,
    String extension,
  ) async {
    final id = const Uuid().v4();
    final path = '$folder/$id.$extension';
    await _client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/$extension',
        upsert: false,
      ),
    );
    final url = _client.storage.from(bucket).getPublicUrl(path);
    return {'url': url, 'path': path};
  }

  Future<Map<String, String>> uploadPdf(
    String folder,
    Uint8List bytes,
    String originalName,
  ) async {
    final id = const Uuid().v4();
    final path = '$folder/$id.pdf';
    await _client.storage.from('pdf-notes').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: false,
      ),
    );
    final url = _client.storage.from('pdf-notes').getPublicUrl(path);
    return {'url': url, 'path': path};
  }

  Future<void> deleteFile(String bucket, String storagePath) async {
    try {
      await _client.storage.from(bucket).remove([storagePath]);
    } catch (e) {
      debugPrint('Storage delete failed for $bucket/$storagePath: $e');
    }
  }
}
