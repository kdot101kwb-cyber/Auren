import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AurenOfflineAudioCache {
  static const _folder = 'auren_podcast_audio';

  static String _safe(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  static Future<Directory> _directory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$_folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String?> download(String episodeId, String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    final dir = await _directory();
    final ext = Uri.tryParse(url)?.path.split('.').last.toLowerCase();
    final suffix = (ext != null && RegExp(r'^[a-z0-9]{2,5}$').hasMatch(ext)) ? ext : 'audio';
    final file = File('${dir.path}/${_safe(episodeId)}.$suffix');
    if (await file.exists() && await file.length() > 0) return file.path;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300 || response.bodyBytes.isEmpty) {
      throw Exception('offline download failed');
    }
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  static Future<void> delete(String episodeId) async {
    final dir = await _directory();
    if (!await dir.exists()) return;
    for (final file in dir.listSync().whereType<File>()) {
      if (file.uri.pathSegments.last.startsWith(_safe(episodeId))) {
        await file.delete();
      }
    }
  }

  static Future<bool> exists(String episodeId) async {
    final dir = await _directory();
    if (!await dir.exists()) return false;
    return dir.listSync().whereType<File>().any(
      (file) => file.uri.pathSegments.last.startsWith(_safe(episodeId)),
    );
  }
}
