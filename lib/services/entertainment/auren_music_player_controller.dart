import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
  int _sessionSkipCount = 0;
  int _sessionCompletionCount = 0;
  DateTime _lastSessionAdaptation = DateTime.fromMillisecondsSinceEpoch(0);
  List<AurenEntertainmentItem> _adaptivePool = const [];
  bool _adaptiveSessionActive = false;
  int _adaptiveCursor = 0;
  final Set<String> _adaptiveServedIds = <String>{};
  String _adaptiveActivity = 'تلقائي';
  String _adaptiveMood = 'الكل';
  String _adaptiveContext = 'تلقائي';
  String _adaptiveContentMode = 'موسيقى';

  AudioPlayer get player => _player;
  AurenEntertainmentItem? get item => _item;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get playing => _player.playing;
  bool get loading => _loading;
  String? get error => _error;
  List<AurenEntertainmentItem> get queue => List.unmodifiable(_queue);
  List<AurenEntertainmentItem> get history => List.unmodifiable(_history);
  bool get adaptiveSessionActive => _adaptiveSessionActive;

  void startAdaptiveSession({
    required List<AurenEntertainmentItem> candidates,
    String activity = 'تلقائي',
    String mood = 'الكل',
    String contextMode = 'تلقائي',
    String contentMode = 'موسيقى',
  }) {
    _adaptivePool = List.unmodifiable(candidates.where((x) => x.mediaUrl.isNotEmpty));
    _adaptiveSessionActive = _adaptivePool.isNotEmpty;
    _adaptiveCursor = 0;
    _adaptiveServedIds
      ..clear()
      ..addAll(_history.take(8).map((x) => x.id));
    _adaptiveActivity = activity;
    _adaptiveMood = mood;
    _adaptiveContext = contextMode;
    _adaptiveContentMode = contentMode;
    _sessionSkipCount = 0;
    _sessionCompletionCount = 0;
    _lastSessionAdaptation = DateTime.fromMillisecondsSinceEpoch(0);
    notifyListeners();
  }

  void stopAdaptiveSession() {
    _adaptiveSessionActive = false;
    _adaptivePool = const [];
    _adaptiveCursor = 0;
    _adaptiveServedIds.clear();
    _sessionSkipCount = 0;
    _sessionCompletionCount = 0;
    notifyListeners();
  }

  Future<void> _onProcessingState(ProcessingState state) async {
    if (state != ProcessingState.completed) return;
    _sessionCompletionCount++;
    await _trackPlayback(completed: true);
    await _recordPodcastEvent('complete');
    await _maybeAutoAdaptSession();
    // A completed item should no longer appear in Continue Listening.
    // Keep it in history/queue, but remove only the resume checkpoint.
    await _clearContinueCheckpoint();
    if (_queue.length > 1) {
      await playNextInQueue();
    } else {
      await _saveState();
    }
  }

  String _playerUrl(String mediaUrl) {
    final value = mediaUrl.trim();
    if (value.isEmpty) return value;
    if (value.startsWith('file://')) return value;
    if (value.startsWith('/')) return Uri.file(value).toString();
    return value;
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
    if (_adaptiveSessionActive) _adaptiveServedIds.add(item.id);
    if (_history.length > 20) _history.removeLast();
    _item = item;
    _position = startAt;
    _lastTrackedSecond = startAt.inSeconds;
    _playTracked = false;
    notifyListeners();
    try {
      await _player.setUrl(_playerUrl(item.mediaUrl));
      _duration = _player.duration ?? Duration.zero;
      if (startAt > Duration.zero) await _player.seek(startAt);
      await _player.play();
      _playTracked = true;
      await _trackPlayback(completed: false, countPlay: true);
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
      await _player.setUrl(_playerUrl(item.mediaUrl));
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
      await _recordPodcastEvent('pause');
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
    if (seconds < 0 || seconds > 0) { await _trackAction('skip'); _sessionSkipCount++; notifyListeners(); }
    final target = _player.position + Duration(seconds: seconds);
    final max = _player.duration;
    final clamped = max == null
        ? target
        : Duration(milliseconds: target.inMilliseconds.clamp(0, max.inMilliseconds).toInt());
    await seek(clamped);
    await _maybeAutoAdaptSession();
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
    bool countPlay = false,
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
        countPlay: countPlay,
      );
    } catch (_) {}
  }

  Future<void> _maybeAutoAdaptSession() async {
    if (!_adaptiveSessionActive || _adaptivePool.isEmpty || !_consumeAdaptationTrigger()) return;

    final currentId = _item?.id;
    final queuedIds = _queue.map((x) => x.id).toSet();
    final baseAvailable = _adaptivePool.where((x) {
      if (x.id == currentId || queuedIds.contains(x.id)) return false;
      if (_adaptiveServedIds.contains(x.id)) return false;
      return true;
    }).toList();

    // Prefer never-served items first; if the pool is exhausted, allow a
    // controlled replay only after all unique candidates have been used.
    final available = baseAvailable.isNotEmpty
        ? baseAvailable
        : _adaptivePool.where((x) => x.id != currentId && !queuedIds.contains(x.id)).toList();
    if (available.isEmpty) return;

    final skipDriven = _sessionSkipCount >= 2;
    final desired = skipDriven ? 2 : 3;
    final selected = <AurenEntertainmentItem>[];

    bool hasKeyword(AurenEntertainmentItem x, List<String> keys) {
      final t = (x.title + ' ' + x.description).toLowerCase();
      return keys.any(t.contains);
    }

    final calmKeys = ['calm', 'chill', 'relax', 'quiet', 'soft', 'sleep', 'هادئ', 'استرخاء', 'نوم'];
    final energyKeys = ['energy', 'energetic', 'workout', 'gym', 'party', 'dance', 'power', 'حماس', 'تمرين', 'حفلة'];

    final recentCreators = <String>{
      ..._queue.take(3).where((x) => x.creatorId.isNotEmpty).map((x) => x.creatorId),
      ..._history.take(4).where((x) => x.creatorId.isNotEmpty).map((x) => x.creatorId),
    };

    int diversityScore(AurenEntertainmentItem x) {
      if (x.creatorId.isEmpty) return 0;
      return recentCreators.contains(x.creatorId) ? -20 : 12;
    }

    int preferenceScore(AurenEntertainmentItem x) {
      final t = (x.title + ' ' + x.description + ' ' + x.type).toLowerCase();
      var score = 0;
      final moodKeys = <String, List<String>>{
        'هادئ': calmKeys,
        'حماس': energyKeys,
        'تركيز': ['focus', 'study', 'ambient', 'concentration', 'تركيز', 'دراسة'],
        'سفر': ['travel', 'trip', 'road', 'journey', 'سفر', 'رحلة'],
        'تسلية': ['fun', 'entertainment', 'comedy', 'تسلية'],
      };
      final contextKeys = <String, List<String>>{
        'صباح': ['morning', 'sunrise', 'صباح'],
        'ليل': ['night', 'midnight', 'ليل'],
        'عمل': ['work', 'office', 'عمل'],
        'رحلة': ['travel', 'road', 'journey', 'رحلة'],
        'استرخاء': calmKeys,
      };
      if (_adaptiveMood != 'الكل') {
        score += (moodKeys[_adaptiveMood] ?? const []).any(t.contains) ? 14 : 0;
      }
      if (_adaptiveContext != 'تلقائي') {
        score += (contextKeys[_adaptiveContext] ?? const []).any(t.contains) ? 8 : 0;
      }
      if (_adaptiveContentMode != 'أي صوت') {
        final mode = _adaptiveContentMode.toLowerCase();
        score += t.contains(mode) ? 7 : 0;
      }
      return score;
    }

    Iterable<AurenEntertainmentItem> ordered;
    if (skipDriven && _adaptiveActivity != 'تمرين' && _adaptiveActivity != 'حفلة') {
      ordered = [
        ...available.where((x) => hasKeyword(x, calmKeys)),
        ...available.where((x) => !hasKeyword(x, calmKeys)),
      ];
    } else if (!skipDriven && (_adaptiveActivity == 'تمرين' || _adaptiveActivity == 'حفلة')) {
      ordered = [
        ...available.where((x) => hasKeyword(x, energyKeys)),
        ...available.where((x) => !hasKeyword(x, energyKeys)),
      ];
    } else {
      ordered = available;
    }

    final ranked = ordered.toList()
      ..sort((a, b) {
        final scoreA = diversityScore(a) + preferenceScore(a);
        final scoreB = diversityScore(b) + preferenceScore(b);
        return scoreB.compareTo(scoreA);
      });

    for (final candidate in ranked) {
      if (selected.length >= desired) break;
      if (!selected.any((x) => x.id == candidate.id)) selected.add(candidate);
    }
    if (selected.isEmpty) return;

    if (skipDriven && _queue.length > 1) {
      _queue.removeAt(1);
    }
    for (final candidate in selected) {
      if (!_queue.any((x) => x.id == candidate.id)) _queue.add(candidate);
    }

    _adaptiveCursor += selected.length;
    _adaptiveServedIds.addAll(selected.map((x) => x.id));
    _sessionSkipCount = 0;
    _sessionCompletionCount = 0;
    await _saveQueueAndHistory();
    notifyListeners();
  }

  Future<void> recordSessionFeedback(String action) async {
    if (action == 'skip') _sessionSkipCount++;
    if (action == 'complete') _sessionCompletionCount++;
    notifyListeners();
  }

  int get sessionSkipCount => _sessionSkipCount;
  int get sessionCompletionCount => _sessionCompletionCount;

  bool _consumeAdaptationTrigger() {
    final now = DateTime.now();
    final triggered = _sessionSkipCount >= 2 || _sessionCompletionCount >= 2;
    if (!triggered || now.difference(_lastSessionAdaptation) < const Duration(seconds: 20)) return false;
    _lastSessionAdaptation = now;
    return true;
  }

  bool get shouldAdaptSession => _sessionSkipCount >= 2 || _sessionCompletionCount >= 2;

  Future<void> _recordPodcastEvent(String event) async {
    final item = _item;
    if (item == null || item.type.toLowerCase() != 'podcast') return;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('recordAurenPodcastEvent');
      await callable.call({
        'event': event,
        'item': {
          'id': item.id,
          'name': item.title,
          'description': item.description,
          'artworkUrl': item.imageUrl,
          'genre': item.type,
          'language': item.language,
          'country': item.country,
          'artist': item.artistName,
        },
      });
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
      if (_position > Duration.zero) {
        // Restore metadata immediately, then resolve the duration so the
        // Continue Listening card can render after app restart.
        await restorePlayback();
      } else {
        notifyListeners();
      }
    } catch (_) {
      await prefs.remove('auren_continue_listening');
    }
  }

  Future<void> _clearContinueCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auren_continue_listening');
  }

  Future<void> clearContinueListening() async {
    _item = null;
    _position = Duration.zero;
    await _player.stop();
    await _clearContinueCheckpoint();
    await _saveQueueAndHistory();
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
