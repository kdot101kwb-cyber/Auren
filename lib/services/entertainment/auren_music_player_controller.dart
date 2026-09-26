import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'entertainment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/entertainment.dart';

class AurenMusicPlayerController extends ChangeNotifier {
  AurenMusicPlayerController._() {
    _player = AudioPlayer();
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.positionStream.listen(_onPosition);
    _player.processingStateStream.listen(_onProcessingState);
    _restore();
  }

  static final AurenMusicPlayerController instance = AurenMusicPlayerController._();
  late final AudioPlayer _player;
  AurenEntertainmentItem? _item;
  final List<AurenEntertainmentItem> _queue = [];
  final List<AurenEntertainmentItem> _history = [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = false;
  String? _error;
  final EntertainmentRepository _signals = EntertainmentRepository();
  int _lastTrackedSecond = 0;
  bool _playTracked = false;

  AudioPlayer get player => _player;
  AurenEntertainmentItem? get item => _item;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get playing => _player.playing;
  bool get loading => _loading;
  String? get error => _error;
  List<AurenEntertainmentItem> get queue => List.unmodifiable(_queue);
  List<AurenEntertainmentItem> get history => List.unmodifiable(_history);

  Future<void> _onProcessingState(ProcessingState state) async {
    if (state != ProcessingState.completed) return;
    await _trackPlayback(completed: true);
    if (_queue.length > 1) {
      await playNextInQueue();
    } else {
      await _saveState();
    }
  }

  Future<void> playItem(AurenEntertainmentItem item, {Duration startAt = Duration.zero}) async {
    if (item.mediaUrl.isEmpty) {
      _error = 'لا يوجد رابط صوت لهذا المحتوى.';
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    _queue.removeWhere((x) => x.id == item.id);
    _queue.insert(0, item);
    _history.removeWhere((x) => x.id == item.id);
    _history.insert(0, item);
    if (_history.length > 20) _history.removeLast();
    _item = item;
    _position = startAt;
    _lastTrackedSecond = startAt.inSeconds;
    _playTracked = false;
    notifyListeners();
    try {
      await _player.setUrl(item.mediaUrl);
      _duration = _player.duration ?? Duration.zero;
      if (startAt > Duration.zero) await _player.seek(startAt);
      await _player.play();
      _playTracked = true;
      await _trackPlayback(completed: false);
      await _saveQueueAndHistory();
      await _saveState();
    } catch (_) {
      _error = 'تعذر تشغيل الصوت.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }


  Future<void> addToQueue(AurenEntertainmentItem item) async {
    if (item.mediaUrl.isEmpty || _queue.any((x) => x.id == item.id)) return;
    _queue.add(item);
    await _saveQueueAndHistory();
    notifyListeners();
  }

  Future<void> removeFromQueue(AurenEntertainmentItem item) async {
    _queue.removeWhere((x) => x.id == item.id);
    await _saveQueueAndHistory();
    notifyListeners();
  }

  Future<void> playNextInQueue() async {
    if (_queue.length < 2) return;
    await playItem(_queue[1]);
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
      if (_player.duration == null) await restorePlayback();
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
    if (seconds < 0 || seconds > 0) await _trackAction('skip');
    final target = _player.position + Duration(seconds: seconds);
    final max = _player.duration;
    final clamped = max == null
        ? target
        : Duration(milliseconds: target.inMilliseconds.clamp(0, max.inMilliseconds).toInt());
    await seek(clamped);
  }

  Future<void> _onPosition(Duration value) async {
    _position = value;
    _duration = _player.duration ?? _duration;
    notifyListeners();
    if (_item != null) {
      final second = value.inSeconds;
      if (second - _lastTrackedSecond >= 10) {
        final delta = second - _lastTrackedSecond;
        _lastTrackedSecond = second;
        await _trackPlayback(seconds: delta, completed: false, countPlay: false);
      }
      if (value.inSeconds % 5 == 0) await _saveState();
    }
  }

  Future<void> _trackPlayback({
    int seconds = 0,
    required bool completed,
    bool countPlay = true,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final item = _item;
    if (uid == null || item == null || !_playTracked) return;
    try {
      await _signals.trackMusicPlayback(
        uid,
        item.id,
        seconds: seconds,
        completed: completed,
        contentType: item.type,
      );
    } catch (_) {}
  }

  Future<void> _trackAction(String action) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final item = _item;
    if (uid == null || item == null) return;
    try {
      await _signals.trackMusicAction(
        uid,
        item.id,
        action: action,
        contentType: item.type,
      );
    } catch (_) {}
  }


  Future<void> _saveQueueAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String encode(AurenEntertainmentItem x) => jsonEncode({
      'id': x.id, 'title': x.title, 'type': x.type, 'description': x.description,
      'imageUrl': x.imageUrl, 'mediaUrl': x.mediaUrl, 'mediaKind': x.mediaKind,
      'creatorId': x.creatorId,
    });
    await prefs.setStringList('auren_music_queue', _queue.map(encode).toList());
    await prefs.setStringList('auren_music_history', _history.map(encode).toList());
  }

  AurenEntertainmentItem decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AurenEntertainmentItem(
      id: map['id'] ?? '', title: map['title'] ?? '', type: map['type'] ?? 'Music',
      description: map['description'] ?? '', imageUrl: map['imageUrl'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '', mediaKind: map['mediaKind'] ?? 'audio',
      creatorId: map['creatorId'] ?? '',
    );
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
    final queueRaw = prefs.getStringList('auren_music_queue') ?? const [];
    final historyRaw = prefs.getStringList('auren_music_history') ?? const [];
    try {
      _queue
        ..clear()
        ..addAll(queueRaw.map(decode));
      _history
        ..clear()
        ..addAll(historyRaw.map(decode));
    } catch (_) {}
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
    await _saveQueueAndHistory();
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
