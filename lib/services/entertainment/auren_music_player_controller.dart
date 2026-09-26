import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/entertainment.dart';

class AurenMusicPlayerController extends ChangeNotifier {
  AurenMusicPlayerController._() {
    _player = AudioPlayer();
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.positionStream.listen(_onPosition);
    _restore();
  }

  static final AurenMusicPlayerController instance = AurenMusicPlayerController._();
  late final AudioPlayer _player;
  AurenEntertainmentItem? _item;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = false;
  String? _error;

  AudioPlayer get player => _player;
  AurenEntertainmentItem? get item => _item;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get playing => _player.playing;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> playItem(AurenEntertainmentItem item, {Duration startAt = Duration.zero}) async {
    if (item.mediaUrl.isEmpty) {
      _error = 'لا يوجد رابط صوت لهذا المحتوى.';
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    _item = item;
    _position = startAt;
    notifyListeners();
    try {
      await _player.setUrl(item.mediaUrl);
      _duration = _player.duration ?? Duration.zero;
      if (startAt > Duration.zero) await _player.seek(startAt);
      await _player.play();
      await _saveState();
    } catch (_) {
      _error = 'تعذر تشغيل الصوت.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> restorePlayback() async {
    final item = _item;
    if (item == null || item.mediaUrl.isEmpty) return;
    try {
      await _player.setUrl(item.mediaUrl);
      _duration = _player.duration ?? Duration.zero;
      if (_position > Duration.zero) await _player.seek(_position);
      notifyListeners();
    } catch (_) {
      _error = 'تعذر استعادة الصوت.';
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else if (_item != null) {
      await _player.play();
    }
    await _saveState();
    notifyListeners();
  }

  Future<void> seek(Duration value) async {
    await _player.seek(value);
    _position = value;
    await _saveState();
    notifyListeners();
  }

  Future<void> skip(int seconds) async {
    final target = _player.position + Duration(seconds: seconds);
    final max = _player.duration;
    final clamped = max == null
        ? target
        : Duration(milliseconds: target.inMilliseconds.clamp(0, max.inMilliseconds));
    await seek(clamped);
  }

  Future<void> _onPosition(Duration value) async {
    _position = value;
    _duration = _player.duration ?? _duration;
    notifyListeners();
    if (value.inSeconds % 5 == 0 && _item != null) {
      await _saveState();
    }
  }

  Future<void> _saveState() async {
    final item = _item;
    if (item == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auren_continue_listening', jsonEncode({
      'id': item.id,
      'title': item.title,
      'type': item.type,
      'description': item.description,
      'imageUrl': item.imageUrl,
      'mediaUrl': item.mediaUrl,
      'mediaKind': item.mediaKind,
      'creatorId': item.creatorId,
      'positionMs': _position.inMilliseconds,
    }));
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auren_continue_listening');
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _item = AurenEntertainmentItem(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        type: map['type'] ?? 'Music',
        description: map['description'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        mediaUrl: map['mediaUrl'] ?? '',
        mediaKind: map['mediaKind'] ?? 'audio',
        creatorId: map['creatorId'] ?? '',
      );
      _position = Duration(milliseconds: (map['positionMs'] ?? 0) as int);
      notifyListeners();
    } catch (_) {
      await prefs.remove('auren_continue_listening');
    }
  }

  Future<void> clearContinueListening() async {
    _item = null;
    _position = Duration.zero;
    await _player.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auren_continue_listening');
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
