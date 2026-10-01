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

  static Future<File?> _cachedFile(String episodeId) async {
    final dir = await _directory();
    if (!await dir.exists()) return null;
    for (final file in dir.listSync().whereType<File>()) {
      if (file.uri.pathSegments.last.startsWith(_safe(episodeId)) &&
          await file.length() > 0) {
        return file;
      }
    }
    return null;
  }

  static Future<String?> cachedPath(String episodeId) async {
    final file = await _cachedFile(episodeId);
    return file?.path;
  }

  static Future<int> cachedBytes(String episodeId) async {
    final file = await _cachedFile(episodeId);
    return file == null ? 0 : file.length();
  }

  static Future<String?> download(String episodeId, String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    final dir = await _directory();
    final ext = Uri.tryParse(url)?.path.split('.').last.toLowerCase();
    final suffix = (ext != null && RegExp(r'^[a-z0-9]{2,5}$').hasMatch(ext)) ? ext : 'audio';
    final file = File('${dir.path}/${_safe(episodeId)}.$suffix');
    if (await file.exists() && await file.length() > 0) return file.path;

    final temp = File('${file.path}.part');
    if (await temp.exists()) await temp.delete();
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('offline download failed');
      }
      final sink = temp.openWrite();
      var bytes = 0;
      try {
        await for (final chunk in response.stream) {
          bytes += chunk.length;
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (bytes == 0) {
        if (await temp.exists()) await temp.delete();
        throw Exception('offline download failed');
      }
      await temp.rename(file.path);
      return file.path;
    } finally {
      client.close();
    }
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

  static Future<bool> exists(String episodeId) async => (await _cachedFile(episodeId)) != null;

  static Future<int> totalBytes() async {
    final dir = await _directory();
    if (!await dir.exists()) return 0;
    var total = 0;
    for (final file in dir.listSync().whereType<File>()) {
      total += await file.length();
    }
    return total;
  }

  static Future<int> totalBytes() async {
    final dir = await _directory();
    if (!await dir.exists()) return 0;
    var total = 0;
    for (final file in dir.listSync().whereType<File>()) {
      total += await file.length();
    }
    return total;
  }

  static Future<List<String>> cachedIds() async {
    final dir = await _directory();
    if (!await dir.exists()) return const [];
    final ids = <String>{};
    for (final file in dir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (name.endsWith('.part')) continue;
      final dot = name.lastIndexOf('.');
      final base = dot > 0 ? name.substring(0, dot) : name;
      if (base.isNotEmpty) ids.add(base);
    }
    return ids.toList();
  }

  static Future<void> clearAll() async {
    final dir = await _directory();
    if (!await dir.exists()) return;
    await dir.delete(recursive: true);
  }
}
