import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../services/tv/auren_tv_service.dart';
import '../../../services/tv/auren_tv_epg_smart_service.dart';
import '../../../services/tv/auren_tv_home_service.dart';
import '../../../services/tv/auren_tv_assistant_service.dart';
import '../../../services/tv/auren_tv_profile_service.dart';
import '../../../services/tv/auren_tv_watch_together_service.dart';

class AurenTvScreen extends StatefulWidget {
  final String? initialWatchTogetherRoomId;
  const AurenTvScreen({super.key, this.initialWatchTogetherRoomId});
  @override State<AurenTvScreen> createState() => _AurenTvScreenState();
}

class _AurenTvScreenState extends State<AurenTvScreen> {
  final _search = TextEditingController();
  String country = '', category = '', query = '', continent = '';
  String tvMode = 'world';
  String newsRegion = 'all';
  String sportCategory = 'all';
  String entertainmentCategory = 'all';
  String countryLabel = 'الدول';
  String quickRegion = '';
  bool lowData = false, onlyFavorites = false, loading = false;
  bool autoLowData = true;
  bool _epgSearching = false;
  List<AurenTvEpgSearchResult> _epgResults = const [];
  ConnectivityResult _connectionType = ConnectivityResult.wifi;
  bool _networkAvailable = true;
  DateTime? _lastRecoveryAt;
  int _bufferEvents = 0;
  Duration _totalBuffering = Duration.zero;
  List<AurenTvSource> sources = const [];
  AurenTvSource? activeSource;
  Set<String> favorites = {};
  VideoPlayerController? player;
  AurenTvChannel? playing;
  bool _pipMode = false;
  final List<String> _watchReactionOverlay = <String>[];
  bool _watchTogether = false;
  bool _watchTogetherReconnectPending = false;
  bool _watchTogetherWasOffline = false;
  String? _watchTogetherRoom;
  final Map<String, String> _tvProfiles = <String, String>{'main': 'Main'};
  String _activeTvProfile = 'main';
  StreamSubscription<AurenTvWatchTogetherRoom>? _watchTogetherSubscription;
  StreamSubscription<QuerySnapshot<Map<String,dynamic>>>? _watchTogetherMessageSubscription;
  StreamSubscription<QuerySnapshot<Map<String,dynamic>>>? _watchTogetherActivitySubscription;
  StreamSubscription<QuerySnapshot<Map<String,dynamic>>>? _watchTogetherReactionSubscription;
  bool _watchTogetherActivityInitialized = false;
  final Set<String> _seenWatchActivityIds = <String>{};
  int _watchTogetherUnreadCount = 0;
  String _watchTogetherLastMessage = '';
  String? _watchTogetherLastMessageId;
  bool _watchTogetherMessagesInitialized = false;
  bool _watchTogetherChatOpen = false;

  Timer? _recoveryTimer;
  Timer? _watchTogetherSyncTimer;
  Timer? _watchTogetherPresenceTimer;
  bool _applyingRemoteWatchState = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  DateTime? _bufferingSince;
  DateTime? _lastProgressAt;
  Duration? _lastPosition;
  bool _recovering = false;
  int _playerGeneration = 0;
  int _failoverAttempts = 0;
  static const int _maxFailoverAttempts = 3;

  static const regions = <String, List<String>>{
    'Africa': ['AF','DZ','AO','BJ','BW','BF','BI','CV','CM','CF','TD','KM','CD','CG','CI','DJ','EG','GQ','ER','SZ','ET','GA','GM','GH','GN','GW','KE','LS','LR','LY','MG','MW','ML','MR','MU','MA','MZ','NA','NE','NG','RW','ST','SN','SC','SL','SO','ZA','SS','SD','TZ','TG','TN','UG','ZM','ZW'],
    'Asia': ['AS','AF','BD','BT','BN','KH','CN','HK','IN','ID','IR','IQ','IL','JP','JO','KZ','KW','KG','LA','LB','MY','MV','MN','MM','NP','KP','PK','PS','PH','QA','SA','SG','KR','LK','SY','TW','TJ','TH','TR','TM','AE','UZ','VN','YE'],
    'Europe': ['AL','AD','AM','AT','AZ','BY','BE','BA','BG','HR','CY','CZ','DK','EE','FI','FR','GE','DE','GR','HU','IS','IE','IT','XK','LV','LI','LT','LU','MT','MD','MC','ME','NL','MK','NO','PL','PT','RO','RU','SM','RS','SK','SI','ES','SE','CH','UA','GB','VA'],
    'Americas': ['AG','AR','BS','BB','BZ','BO','BR','CA','CL','CO','CR','CU','DM','DO','EC','SV','GD','GT','GY','HT','HN','JM','MX','NI','PA','PY','PE','KN','LC','VC','SR','TT','US','UY','VE'],
    'Oceania': ['AU','FJ','KI','MH','FM','NR','NZ','PW','PG','WS','SB','TO','TV','VU'],
  };

  @override void initState() {
    super.initState();
    final initialRoomId = widget.initialWatchTogetherRoomId?.trim();
    if (initialRoomId != null && initialRoomId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openWatchTogetherRoom(initialRoomId));
    }
    AurenTvService.instance.favorites().then((v) { if (mounted) setState(() => favorites = v); });
    Future.wait([AurenTvProfileService.instance.profiles(), AurenTvProfileService.instance.activeProfileId()]).then((v) { if (!mounted) return; final ps=v[0] as List<AurenTvProfile>; final active=v[1] as String; setState(() { _activeTvProfile=active; _tvProfiles..clear()..addEntries(ps.map((p)=>MapEntry(p.id,p.name))); }); });
    AurenTvService.instance.autoRefreshSources(limit: 150).then((_) => AurenTvService.instance.refreshEpgAndSyncReminders()).catchError((_) {});
    _recoveryTimer = Timer.periodic(const Duration(seconds: 3), (_) => _monitorPlayback());
    Connectivity().checkConnectivity().then((results) {
      if (!mounted) return;
      final type = results.isEmpty ? ConnectivityResult.none : results.first;
      setState(() { _connectionType = type; if (autoLowData && (type == ConnectivityResult.mobile || type == ConnectivityResult.none)) lowData = true; });
    });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final available = results.any((r) => r != ConnectivityResult.none);
      final type = results.isEmpty ? ConnectivityResult.none : results.first;
      setState(() {
        _networkAvailable = available;
        _connectionType = type;
        if (autoLowData && (type == ConnectivityResult.mobile || type == ConnectivityResult.none)) lowData = true;
        if (autoLowData && type == ConnectivityResult.wifi) lowData = false;
      });
      if (!available && _watchTogether && _watchTogetherRoom != null) {
        _watchTogetherWasOffline = true;
        unawaited(AurenTvWatchTogetherService.instance.heartbeat(_watchTogetherRoom!, online: false));
      }
      if (available && _watchTogetherWasOffline) unawaited(_handleWatchTogetherReconnect());
      if (available && player?.value.isInitialized == true && player!.value.isBuffering && !_recovering) {
        _recoverPlayback(reason: 'عاد الاتصال بالإنترنت');
      }
    });
    AurenTvService.instance.sources().then((v) async {
      final defaultId = await AurenTvService.instance.defaultSourceId();
      if (!mounted) return;
      setState(() {
        sources = v;
        final matches = v.where((x) => x.id == defaultId && x.enabled).toList();
        activeSource = matches.isEmpty ? null : matches.first;
      });
    });
  }

  Future<void> _handleWatchTogetherReconnect() async {
    final roomId = _watchTogetherRoom;
    if (!_watchTogether || roomId == null || !_watchTogetherWasOffline) return;
    _watchTogetherWasOffline = false;
    try {
      final service = AurenTvWatchTogetherService.instance;
      final room = await service.getRoom(roomId);
      if (room == null) {
        _watchTogetherWasOffline = true;
        return;
      }
      await service.heartbeat(roomId, online: true);
      await service.notifyActivity(roomId, type: 'reconnected');
      _watchTogetherReconnectPending = true;
      await _applyWatchTogetherRoomState(room);
      _watchTogetherReconnectPending = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عاد اتصال Watch Together • تمت إعادة المزامنة')));
      }
    } catch (_) {
      _watchTogetherReconnectPending = false;
      _watchTogetherWasOffline = true;
    }
  }

  Future<void> _searchEpg() async {
    final q = _search.text.trim();
    if (q.length < 2) return;
    setState(() => _epgSearching = true);
    final results = await AurenTvService.instance.searchEpg(q, source: activeSource, hours: 48);
    if (!mounted) return;
    setState(() { _epgResults = results; _epgSearching = false; });
  }

  Future<void> _showEpgReminderCenter() async {
    await AurenTvService.instance.cleanupExpiredEpgReminders();
    final reminders = await AurenTvService.instance.epgReminders();
    if (!mounted) return;
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(child: SizedBox(height: MediaQuery.of(ctx).size.height * .72, child: reminders.isEmpty ? const Center(child: Text('لا توجد تذكيرات EPG حالياً.')) : ListView.separated(padding: const EdgeInsets.all(12), itemCount: reminders.length + 1, separatorBuilder: (_, __) => const SizedBox(height: 6), itemBuilder: (_, i) {
      if (i == 0) return const ListTile(title: Text('مركز تذكيرات EPG', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('إدارة البرامج التي طلبت AUREN تذكيرك بها.'));
      final r = reminders[i - 1]; final start = DateTime.tryParse(r.startIso)?.toLocal(); final diff = start?.difference(DateTime.now());
      final label = start == null ? r.startIso : ((diff!.isNegative ? 'بدأ البرنامج' : diff.inHours > 0 ? 'بعد ${diff.inHours}س ${diff.inMinutes.remainder(60)}د' : 'بعد ${diff.inMinutes} دقيقة') + ' • ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}');
      final item = AurenTvEpgSearchResult(channelId: r.channelId, title: r.title, startIso: r.startIso, stopIso: r.startIso, state: 'next');
      return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.notifications_active_outlined)), title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text(label), trailing: Wrap(children: [IconButton(tooltip: 'تعديل التذكير', onPressed: () async { final before = await showModalBottomSheet<Duration>(context: ctx, builder: (s) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [const ListTile(title: Text('تعديل وقت التذكير')), for (final m in const [5, 10, 15, 30, 60]) ListTile(title: Text('قبل $m دقيقة'), onTap: () => Navigator.pop(s, Duration(minutes: m)))]))); if (before == null || !ctx.mounted) return; final ok = await AurenTvService.instance.updateEpgReminder(item, before: before); if (ctx.mounted) { Navigator.pop(ctx); if (ok) await _showEpgReminderCenter(); } }, icon: const Icon(Icons.edit_notifications_outlined)), IconButton(tooltip: 'إلغاء التذكير', onPressed: () async { await AurenTvService.instance.removeEpgReminder(item); if (ctx.mounted) { Navigator.pop(ctx); await _showEpgReminderCenter(); } }, icon: const Icon(Icons.notifications_off_outlined))])));
    }))));
  }
  void _showFloatingReaction(String emoji) {
    if (!mounted || emoji.trim().isEmpty) return;
    setState(() {
      _watchReactionOverlay.add(emoji);
      if (_watchReactionOverlay.length > 8) {
        _watchReactionOverlay.removeAt(0);
      }
    });
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final index = _watchReactionOverlay.indexOf(emoji);
      if (index >= 0) setState(() => _watchReactionOverlay.removeAt(index));
    });
  }

  void _togglePip() {
    if (player == null || playing == null) return;
    setState(() => _pipMode = !_pipMode);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_pipMode ? 'Mini Player مفعّل' : 'Mini Player مغلق')));
  }

  Future<void> _showTvProfiles() async {
    final profiles = await AurenTvProfileService.instance.profiles();
    final active = await AurenTvProfileService.instance.activeProfileId();
    if (!mounted) return;
    final action = await showModalBottomSheet<String>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(
      child: SizedBox(height: MediaQuery.of(ctx).size.height * .55, child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const ListTile(title: Text('TV Profiles', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('ملفات مشاهدة منفصلة على هذا الجهاز.')),
          for (final p in profiles) ListTile(
            leading: Icon(p.id == active ? Icons.radio_button_checked : Icons.radio_button_off),
            title: Text(p.name), subtitle: Text(p.id == active ? 'نشط الآن' : ''),
            onTap: () => Navigator.pop(ctx, 'select:' + p.id),
            trailing: p.id == 'main' ? null : IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => Navigator.pop(ctx, 'delete:' + p.id)),
          ),
          ListTile(leading: const Icon(Icons.add), title: const Text('إضافة ملف'), onTap: () => Navigator.pop(ctx, 'add')),
        ],
      )),
    ));
    if (!mounted || action == null) return;
    if (action == 'add') {
      final name = await showDialog<String>(context: context, builder: (ctx) {
        final input = TextEditingController();
        return AlertDialog(title: const Text('إضافة TV Profile'), content: TextField(controller: input, autofocus: true, decoration: const InputDecoration(hintText: 'اسم الملف')), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, input.text.trim()), child: const Text('حفظ')),
        ]);
      });
      if (name != null && name.isNotEmpty) {
        await AurenTvProfileService.instance.saveProfile(name);
        final ps = await AurenTvProfileService.instance.profiles();
        if (mounted) setState(() { _tvProfiles..clear()..addEntries(ps.map((p) => MapEntry(p.id, p.name))); });
      }
    } else if (action.startsWith('select:')) {
      final id = action.substring(7);
      await AurenTvProfileService.instance.setActiveProfile(id);
      if (mounted) setState(() => _activeTvProfile = id);
    } else if (action.startsWith('delete:')) {
      await AurenTvProfileService.instance.deleteProfile(action.substring(7));
    }
  }

  Future<AurenTvChannel?> _findWatchTogetherChannel(String channelId) async {
    try {
      for (final source in (await AurenTvService.instance.sources()).where((x) => x.enabled)) {
        final channels = await AurenTvService.instance.loadSource(source, limit: 500);
        for (final channel in channels) {
          if (channel.id == channelId) return channel;
        }
      }
      final channels = await AurenTvService.instance.load();
      for (final channel in channels) {
        if (channel.id == channelId) return channel;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _applyWatchTogetherRoomState(AurenTvWatchTogetherRoom room) async {
    if (room.channelId == null) return;
    final channel = await _findWatchTogetherChannel(room.channelId!);
    if (!mounted || channel == null) return;
    await play(channel, syncWatchTogether: false, autoplay: false);
    final p = player;
    if (p == null || !p.value.isInitialized) return;
    _applyingRemoteWatchState = true;
    try {
      final position = Duration(milliseconds: (room.positionSeconds * 1000).round());
      await p.seekTo(position);
      if (room.isPlaying && !lowData) {
        await p.play();
      } else {
        await p.pause();
      }
      if (mounted) setState(() {});
    } finally {
      _applyingRemoteWatchState = false;
    }
  }

  Future<void> _openWatchTogetherRoom(String roomId) async {
    final service = AurenTvWatchTogetherService.instance;
    try {
      final room = await service.getRoom(roomId);
      if (!mounted) return;
      if (room == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الغرفة غير متاحة أو لم تعد عضواً فيها.')));
        return;
      }
      await _connectWatchTogetherRoom(room, applyState: true);
      if (mounted) await _showWatchTogetherStatus(room);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح غرفة Watch Together.')));
    }
  }

  Future<void> _connectWatchTogetherRoom(AurenTvWatchTogetherRoom room, {bool applyState = false}) async {
    final service = AurenTvWatchTogetherService.instance;
    final roomId = room.id;
    await _watchTogetherSubscription?.cancel();
    await _watchTogetherMessageSubscription?.cancel();
    await _watchTogetherActivitySubscription?.cancel();
    await _watchTogetherReactionSubscription?.cancel();
    _watchTogetherSyncTimer?.cancel();
    _watchTogetherPresenceTimer?.cancel();
    await service.initializePushNotifications();
    if (!mounted) return;
    setState(() {
      _watchTogether = true;
      _watchTogetherRoom = roomId;
      _watchTogetherReconnectPending = false;
      _watchTogetherWasOffline = false;
      _watchTogetherActivityInitialized = false;
      _watchTogetherMessagesInitialized = false;
      _watchTogetherUnreadCount = 0;
      _watchTogetherLastMessage = '';
      _watchTogetherLastMessageId = null;
      _seenWatchActivityIds.clear();
    });
    if (applyState) await _applyWatchTogetherRoomState(room);
    await service.heartbeat(roomId);
    _watchTogetherPresenceTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_watchTogetherRoom == roomId) {
        try { await service.heartbeat(roomId); } catch (_) {}
      }
    });
    _watchTogetherSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_watchTogetherRoom != roomId || _applyingRemoteWatchState || player == null || !player!.value.isInitialized) return;
      try {
        await service.sync(roomId, positionSeconds: player!.value.position.inMilliseconds / 1000.0, isPlaying: player!.value.isPlaying);
      } catch (_) {}
    });
    _startWatchTogetherMessageTracking(roomId);
    _startWatchTogetherActivityTracking(roomId);
    _watchTogetherSubscription = service.watch(roomId).listen((remote) async {
      if (!mounted || remote.status == 'closed') return;
      final current = playing;
      if (current == null || remote.channelId != current.id) return;
      final p = player;
      if (p == null || !p.value.isInitialized) return;
      _applyingRemoteWatchState = true;
      try {
        final remotePos = Duration(milliseconds: (remote.positionSeconds * 1000).round());
        if ((p.value.position - remotePos).abs() > const Duration(seconds: 3)) await p.seekTo(remotePos);
        if (remote.isPlaying && !p.value.isPlaying && !lowData) await p.play();
        if (!remote.isPlaying && p.value.isPlaying) await p.pause();
      } finally {
        _applyingRemoteWatchState = false;
      }
    });
    _watchTogetherReactionSubscription = service.reactions(roomId).listen((snap) {
      if (!mounted) return;
      for (final doc in snap.docChanges.where((change) => change.type == DocumentChangeType.added)) {
        final emoji = doc.doc.data()?['emoji']?.toString();
        if (emoji != null && emoji.isNotEmpty) _showFloatingReaction(emoji);
      }
    });
  }

  Future<void> _showWatchTogether() async {
    final service = AurenTvWatchTogetherService.instance;
    final action = await showDialog<String>(context: context, builder: (ctx) {
      final input = TextEditingController();
      return AlertDialog(
        title: Text(_watchTogetherRoom == null ? 'Watch Together' : 'Watch Together • متصل'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (playing != null) Text('القناة: ' + playing!.name),
          TextField(controller: input, decoration: const InputDecoration(labelText: 'اسم الغرفة')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'join'), child: const Text('دخول')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'create'), child: const Text('إنشاء')),
        ],
      );
    });
    if (!mounted || action == null) return;
    try {
      AurenTvWatchTogetherRoom? room;
      if (action == 'create') {
        if (playing == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شغّل قناة أولاً لإنشاء غرفة.')));
          return;
        }
        room = await service.create(title: 'AUREN TV • ' + playing!.name, channelId: playing!.id, channelName: playing!.name);
      } else {
        final code = await showDialog<String>(context: context, builder: (ctx) {
          final input = TextEditingController();
          return AlertDialog(title: const Text('Invite Code'), content: TextField(controller: input, textCapitalization: TextCapitalization.characters), actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, input.text.trim()), child: const Text('دخول')),
          ]);
        });
        if (code != null && code.isNotEmpty) room = await service.join(code);
      }
      if (room == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تأكد من تسجيل الدخول وبيانات الغرفة.')));
        return;
      }
      await _connectWatchTogetherRoom(room, applyState: action == 'join');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الغرفة جاهزة • الكود: ' + room.inviteCode + ' • الأعضاء: ' + room.memberIds.length.toString())));
      await _showWatchTogetherStatus(room);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إنشاء أو دخول الغرفة.')));
    }
  }

  String _presenceLabel(Map<String,dynamic>? data, DateTime now) {
    if (data == null) return 'غير متصل';
    final last = data['lastSeen'];
    if (last is Timestamp) {
      final elapsed = now.difference(last.toDate());
      final seconds = elapsed.inSeconds;
      if (data['online'] == true && seconds <= 30) return 'متصل الآن';
      if (seconds <= 120) return 'عاد مؤخراً';
      if (elapsed.inMinutes < 60) return 'آخر ظهور منذ ' + elapsed.inMinutes.toString() + ' دقيقة';
      if (elapsed.inHours < 24) return 'آخر ظهور منذ ' + elapsed.inHours.toString() + ' ساعة';
      return 'آخر ظهور منذ ' + elapsed.inDays.toString() + ' يوم';
    }
    return 'غير متصل';
  }

  String _watchActivityLabel(String type) {
    switch (type) {
      case 'joined': return 'دخل الغرفة';
      case 'left': return 'غادر الغرفة';
      case 'reconnected': return 'عاد للاتصال';
      default: return 'نشاط جديد';
    }
  }

  Widget _watchTogetherReactions(AurenTvWatchTogetherRoom room) {
    const emojis = ['❤️','😂','🔥','👏','😍','😮','👍','🎉'];
    final service = AurenTvWatchTogetherService.instance;
    return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: service.reactions(room.id),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String,dynamic>>>[];
        return Wrap(
          spacing: 4,
          children: emojis.map((emoji) => ActionChip(
            label: Text(emoji, style: const TextStyle(fontSize: 18)),
            onPressed: () => service.sendReaction(room.id, emoji),
          )).toList(),
        );
      },
    );
  }

  String _watchMemberName(Map<String,dynamic>? data, String uid) {
    final name = data?['displayName'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return 'عضو ${uid.substring(0, uid.length > 6 ? 6 : uid.length)}';
  }

  String _watchChatTime(dynamic value) {
    if (value is! Timestamp) return '';
    final d = value.toDate().toLocal();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${h}:${m}';
  }

  void _startWatchTogetherActivityTracking(String roomId) {
    _watchTogetherActivityInitialized = false;
    _seenWatchActivityIds.clear();
    final service = AurenTvWatchTogetherService.instance;
    _watchTogetherActivitySubscription = service.activity(roomId).listen((snap) {
      if (!mounted || _watchTogetherRoom != roomId) return;
      final changes = snap.docChanges.where((change) => change.type == DocumentChangeType.added);
      if (!_watchTogetherActivityInitialized) {
        _seenWatchActivityIds.addAll(snap.docs.map((doc) => doc.id));
        _watchTogetherActivityInitialized = true;
        return;
      }
      for (final change in changes) {
        final doc = change.doc;
        if (!_seenWatchActivityIds.add(doc.id)) continue;
        final data = doc.data();
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final actor = data?['actorUid']?.toString();
        final type = data?['type']?.toString() ?? '';
        if (actor == null || actor == uid || !{'joined', 'left', 'reconnected'}.contains(type)) continue;
        final label = _watchActivityLabel(type);
        unawaited(service.notifyRoomActivity(
          roomId: roomId,
          eventId: doc.id,
          title: 'نشاط في غرفة المشاهدة',
          body: label,
        ));
      }
    });
  }

  void _startWatchTogetherMessageTracking(String roomId) {
    _watchTogetherMessageSubscription?.cancel();
    _watchTogetherActivitySubscription?.cancel();
    _watchTogetherUnreadCount = 0;
    _watchTogetherLastMessage = '';
    _watchTogetherLastMessageId = null;
    _watchTogetherMessagesInitialized = false;
    final service = AurenTvWatchTogetherService.instance;
    _watchTogetherMessageSubscription = service.messages(roomId).listen((snap) {
      if (!mounted || _watchTogetherRoom != roomId) return;
      final docs = snap.docs;
      if (docs.isEmpty) return;
      final newest = docs.first;
      final data = newest.data();
      final textValue = (data['text'] as String? ?? '').trim();
      final sender = (data['type'] == 'system') ? 'AUREN' : ((data['senderName'] as String?)?.trim().isNotEmpty == true ? data['senderName'] as String : 'عضو');
      final preview = textValue.isEmpty ? '' : '$sender: $textValue';
      final isNew = _watchTogetherLastMessageId != newest.id;
      if (!_watchTogetherMessagesInitialized) {
        _watchTogetherMessagesInitialized = true;
        _watchTogetherLastMessageId = newest.id;
        if (mounted) setState(() => _watchTogetherLastMessage = preview);
        return;
      }
      if (!isNew) return;
      _watchTogetherLastMessageId = newest.id;
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (data['type'] != 'system' && data['senderUid'] != currentUid && !_watchTogetherChatOpen) {
        unawaited(service.notifyIncomingMessage(roomId: roomId, sender: sender, message: textValue));
      }
      if (mounted) setState(() {
        _watchTogetherLastMessage = preview;
        _watchTogetherUnreadCount += 1;
      });
    });
  }

  Future<void> _showWatchTogetherChat(AurenTvWatchTogetherRoom room) async {
    final service = AurenTvWatchTogetherService.instance;
    final controller = TextEditingController();
    Timer? typingTimer;
    _watchTogetherChatOpen = true;
    if (_watchTogetherRoom == room.id) {
      setState(() => _watchTogetherUnreadCount = 0);
      unawaited(service.markMessagesRead(room.id, lastMessageId: _watchTogetherLastMessageId));
    }
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * .72,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(Icons.chat_bubble_outline),
                    SizedBox(width: 8),
                    Text('Watch Together Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _watchTogetherReactions(room)),
                StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                  stream: service.typing(room.id),
                  builder: (ctx, snap) {
                    final active = (snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String,dynamic>>>[])
                        .where((d) => d.data()['typing'] == true && d.id != FirebaseAuth.instance.currentUser?.uid)
                        .length;
                    if (active == 0) return const SizedBox(height: 2);
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Align(alignment: Alignment.centerLeft, child: Text('عضو يكتب…', style: TextStyle(fontSize: 12))),
                    );
                  },
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                    stream: service.readReceipts(room.id),
                    builder: (ctx, receiptsSnap) {
                      final receipts = receiptsSnap.data?.docs ?? const <QueryDocumentSnapshot<Map<String,dynamic>>>[];
                      final myUid = FirebaseAuth.instance.currentUser?.uid;
                      final otherReceipts = receipts.where((d) => d.id != myUid).map((d) => d.data()['lastReadAt']).whereType<Timestamp>().toList();
                      final hasSeen = (Timestamp? createdAt) => createdAt != null && otherReceipts.any((r) => !r.toDate().isBefore(createdAt.toDate()));
                      return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                    stream: service.messages(room.id),
                    builder: (ctx, snap) {
                      final docs = snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String,dynamic>>>[];
                      if (docs.isEmpty) return const Center(child: Text('ابدأ المحادثة أثناء المشاهدة'));
                      unawaited(service.markMessagesRead(room.id, lastMessageId: docs.isEmpty ? _watchTogetherLastMessageId : docs.first.id));
                      return ListView.builder(
                        reverse: true,
                        itemCount: docs.length,
                        itemBuilder: (_, index) {
                          final d = docs[index].data();
                          final mine = d['senderUid'] == FirebaseAuth.instance.currentUser?.uid;
                          final system = d['type'] == 'system';
                          if (system) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                              child: Center(child: Text(
                                d['text'] as String? ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                              )),
                            );
                          }
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: mine ? Theme.of(ctx).colorScheme.primaryContainer : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(d['text'] as String? ?? ''),
                                  const SizedBox(height: 2),
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text(_watchChatTime(d['createdAt']), style: TextStyle(fontSize: 10, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                                    if (mine) ...[
                                      const SizedBox(width: 5),
                                      Text(hasSeen(d['createdAt'] is Timestamp ? d['createdAt'] as Timestamp : null) ? '✓✓' : '✓', style: TextStyle(fontSize: 10, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                                    ],
                                  ]),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      },
                    );
                  },
                ),
              ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(ctx).viewInsets.bottom + 8),
                  child: Row(children: [
                    Expanded(child: TextField(controller: controller, maxLength: 500, onChanged: (_) { typingTimer?.cancel(); service.setTyping(room.id, true); typingTimer = Timer(const Duration(seconds: 2), () { service.clearTyping(room.id); }); }, textInputAction: TextInputAction.send,
                      onSubmitted: (_) async { final v=controller.text; controller.clear(); typingTimer?.cancel(); await service.clearTyping(room.id); await service.sendMessage(room.id, v); },
                      decoration: const InputDecoration(hintText: 'اكتب رسالة…', counterText: ''))),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async { final v=controller.text; controller.clear(); typingTimer?.cancel(); await service.setTyping(room.id, false); await service.sendMessage(room.id, v); },
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      _watchTogetherChatOpen = false;
      typingTimer?.cancel();
      await service.clearTyping(room.id);
      controller.dispose();
    }
  }

  Future<void> _showWatchTogetherStatus(AurenTvWatchTogetherRoom initial) async {
    final service = AurenTvWatchTogetherService.instance;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StreamBuilder<AurenTvWatchTogetherRoom>(
        stream: service.watch(initial.id),
        initialData: initial,
        builder: (ctx, snap) {
          final room = snap.data ?? initial;
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final isHost = uid != null && uid == room.hostUid;
          return SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: Icon(isHost ? Icons.star : Icons.groups),
                title: Text(room.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('الكود: ${room.inviteCode} • ${room.memberIds.length}/8 • ${room.status}'),
              ),
              ListTile(leading: const Icon(Icons.chat_bubble_outline), title: const Text('الدردشة'), subtitle: Text(_watchTogetherUnreadCount > 0 ? '$_watchTogetherUnreadCount رسالة جديدة${_watchTogetherLastMessage.isEmpty ? '' : ' • $_watchTogetherLastMessage'}' : (_watchTogetherLastMessage.isEmpty ? 'فتح الدردشة' : _watchTogetherLastMessage), maxLines: 2, overflow: TextOverflow.ellipsis), trailing: _watchTogetherUnreadCount > 0 ? Badge(label: Text('$_watchTogetherUnreadCount')) : null, onTap: () { Navigator.pop(context); _showWatchTogetherChat(room); }),
              const Divider(),
              StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                stream: service.activity(room.id),
                builder: (ctx, snap) {
                  final events = snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String,dynamic>>>[];
                  if (events.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'آخر النشاطات • ' + events.take(3).map((d) => _watchActivityLabel(d.data()['type'] as String? ?? '')).join(' • '),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
              StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(

                stream: service.presence(room.id),
                builder: (ctx, presenceSnap) {
                  final now = DateTime.now();
                  final docs = <String,Map<String,dynamic>>{
                    for (final d in presenceSnap.data?.docs ?? const <QueryDocumentSnapshot<Map<String,dynamic>>>[])
                      d.id: d.data(),
                  };
                  return Column(children: [
                    for (final id in room.memberIds)
                      ListTile(
                        dense: true,
                        leading: Icon(id == room.hostUid ? Icons.workspace_premium : Icons.person_outline),
                        title: Text(id == uid ? 'أنت' : _watchMemberName(docs[id], id)),
                        subtitle: Text(id == room.hostUid ? 'Host • '+_presenceLabel(docs[id], now) : 'Member • '+_presenceLabel(docs[id], now)),
                      ),
                  ]);
                },
              ),


              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () async { await service.leave(room.id); if (mounted) { _watchTogetherSubscription?.cancel(); _watchTogetherMessageSubscription?.cancel(); _watchTogetherSyncTimer?.cancel(); _watchTogetherPresenceTimer?.cancel(); setState(() { _watchTogetherRoom = null; _watchTogether = false; }); Navigator.pop(ctx); } },
                  icon: const Icon(Icons.exit_to_app), label: const Text('مغادرة'),
                )),
                if (isHost) ...[
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(
                    onPressed: () async { await service.close(room.id); if (mounted) { _watchTogetherSubscription?.cancel(); _watchTogetherMessageSubscription?.cancel(); _watchTogetherSyncTimer?.cancel(); setState(() { _watchTogetherRoom = null; _watchTogether = false; }); Navigator.pop(ctx); } },
                    icon: const Icon(Icons.close), label: const Text('إغلاق'),
                  )),
                ],
              ]),
            ]),
          ));
        },
      ),
    );
  }

  Future<void> _showTvAssistant() async {
    final controller = TextEditingController();
    AurenTvAssistantResult? result;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .82,
          child: Column(children: [
            const ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('AUREN TV Assistant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              subtitle: Text('اكتب طلبك بلغة طبيعية: قنوات السودان، رياضة، أو برنامج معين.'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'مثلاً: مباريات كرة القدم أو قنوات السودان',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final q = controller.text.trim();
                      if (q.length < 2) return;
                      final r = await AurenTvAssistantService.instance.ask(q, source: activeSource);
                      if (ctx.mounted) setSheetState(() => result = r);
                    },
                  ),
                ),
                onSubmitted: (_) async {
                  final q = controller.text.trim();
                  if (q.length < 2) return;
                  final r = await AurenTvAssistantService.instance.ask(q, source: activeSource);
                  if (ctx.mounted) setSheetState(() => result = r);
                },
              ),
            ),
            Expanded(
              child: result == null
                  ? const Center(child: Text('جرّب: "قنوات السودان" أو "أفلام" أو اسم برنامج.'))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: Text(result!.message))),
                        if (result!.programs.isNotEmpty)
                          const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('نتائج EPG', style: TextStyle(fontWeight: FontWeight.w800))),
                        for (final p in result!.programs)
                          Card(child: ListTile(
                            leading: Icon(p.state == 'now' ? Icons.play_circle : Icons.schedule),
                            title: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(DateTime.tryParse(p.startIso)?.toLocal().toString() ?? p.startIso),
                            onTap: () async {
                              final ch = await AurenTvService.instance.findChannelForEpgId(p.channelId, source: activeSource);
                              if (ch != null && ctx.mounted) { Navigator.pop(ctx); play(ch); }
                            },
                          )),
                        if (result!.channels.isNotEmpty)
                          const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('القنوات', style: TextStyle(fontWeight: FontWeight.w800))),
                        for (final ch in result!.channels)
                          Card(child: ListTile(
                            leading: ch.logo.isEmpty ? const CircleAvatar(child: Icon(Icons.tv)) : CircleAvatar(backgroundImage: NetworkImage(ch.logo)),
                            title: Text(ch.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${ch.country} • ${ch.language} • ${ch.category}'),
                            trailing: const Icon(Icons.play_circle_outline),
                            onTap: () { Navigator.pop(ctx); play(ch); },
                          )),
                      ],
                    ),
            ),
          ]),
        ),
      )),
    );
  }

  Future<void> _showTvHome() async {
    final channels = await AurenTvHomeService.instance.personalizedChannels(limit: 24);
    if (!mounted) return;
    final guides = await AurenTvHomeService.instance.multiChannelGuide(channels, hours: 48, perChannel: 4, source: activeSource);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => SafeArea(child: SizedBox(
        height: MediaQuery.of(ctx).size.height * .82,
        child: Column(children: [
          const ListTile(title: Text('AUREN TV • For You', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), subtitle: Text('قنوات مرتبة حسب مفضلاتك ومشاهدتك السابقة.')),
          Expanded(child: guides.isEmpty ? const Center(child: Text('لا توجد قنوات مقترحة حالياً.')) : ListView.separated(
            padding: const EdgeInsets.all(12), itemCount: guides.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final g = guides[i]; final now = g.nowNext?['current']; final next = g.nowNext?['next'];
              return Card(child: ListTile(
                leading: g.channel.logo.isEmpty ? const CircleAvatar(child: Icon(Icons.tv)) : CircleAvatar(backgroundImage: NetworkImage(g.channel.logo)),
                title: Text(g.channel.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(g.channel.country + ' • ' + ((now?.toString() ?? '').isEmpty ? 'لا يوجد برنامج الآن' : 'الآن: ' + (now?.toString() ?? '')) + ((next?.toString() ?? '').isEmpty ? '' : ' • القادم: ' + (next?.toString() ?? '')), maxLines: 3, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.play_circle_outline),
                onTap: () { Navigator.pop(ctx); play(g.channel); },
              ));
            },
          )),
        ]),
      )),
    );
  }

  Future<void> _showMultiChannelEpg() async {
    final base = activeSource != null
        ? await AurenTvService.instance.loadSource(activeSource!, limit: lowData ? 80 : 150)
        : await AurenTvService.instance.load(country: country, category: category);
    final channels = base.where((c) => query.isEmpty || _normalizeSearch(c.name + ' ' + c.country + ' ' + c.language + ' ' + c.category).contains(query)).take(30).toList();
    final guides = await AurenTvHomeService.instance.multiChannelGuide(channels, hours: 48, perChannel: 6, source: activeSource);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => SafeArea(child: SizedBox(
        height: MediaQuery.of(ctx).size.height * .86,
        child: Column(children: [
          const ListTile(title: Text('Multi-Channel EPG', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('الآن والقادم والبرامج التالية عبر عدة قنوات.')),
          Expanded(child: guides.isEmpty ? const Center(child: Text('لا توجد بيانات EPG للقنوات الحالية.')) : ListView.separated(
            padding: const EdgeInsets.all(12), itemCount: guides.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final g = guides[i];
              return Card(child: ExpansionTile(
                leading: g.channel.logo.isEmpty ? const CircleAvatar(child: Icon(Icons.tv)) : CircleAvatar(backgroundImage: NetworkImage(g.channel.logo)),
                title: Text(g.channel.name),
                subtitle: Text((g.nowNext?['current'] ?? '').isEmpty ? 'لا يوجد برنامج الآن' : 'الآن: ' + (g.nowNext?['current'] ?? '')),
                children: [
                  if (g.schedule.isEmpty) const ListTile(title: Text('لا توجد برامج إضافية في الدليل.'))
                  else for (final item in g.schedule) ListTile(
                    dense: true, leading: Icon(item['state'] == 'now' ? Icons.play_arrow : Icons.schedule),
                    title: Text(item['title']?.toString() ?? ''),
                    subtitle: Text(() {
                      final s = DateTime.tryParse(item['startIso']?.toString() ?? '')?.toLocal();
                      final e = DateTime.tryParse(item['stopIso']?.toString() ?? '')?.toLocal();
                      if (s == null || e == null) return '';
                      return TimeOfDay.fromDateTime(s).format(ctx) + ' — ' + TimeOfDay.fromDateTime(e).format(ctx);
                    }()),
                    onTap: () { Navigator.pop(ctx); play(g.channel); },
                  ),
                ],
              ));
            },
          )),
        ]),
      )),
    );
  }

  Future<void> _showEpgCalendar() async {
    if (playing == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شغّل قناة أولاً لعرض جدولها.'))); return; }
    final channel = playing!;
    final items = await AurenTvService.instance.smartScheduleForChannel(channel, source: activeSource, hours: 48);
    if (!mounted) return;
    DateTime day = DateTime.now();
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
      final filtered = items.where((x) { final d = DateTime.tryParse(x['startIso'] ?? '')?.toLocal(); return d != null && d.year == day.year && d.month == day.month && d.day == day.day; }).toList();
      return SafeArea(child: SizedBox(height: MediaQuery.of(ctx).size.height * .78, child: Column(children: [
        ListTile(title: Text('EPG Calendar • ' + channel.name), subtitle: Text('اليوم: ' + day.day.toString() + '/' + day.month.toString() + '/' + day.year.toString())),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [TextButton(onPressed: () => setSheetState(() => day = DateTime.now()), child: const Text('اليوم')), TextButton(onPressed: () => setSheetState(() => day = DateTime.now().add(const Duration(days: 1))), child: const Text('غداً'))]),
        Expanded(child: filtered.isEmpty ? const Center(child: Text('لا توجد بيانات EPG لهذا اليوم.')) : ListView.separated(padding: const EdgeInsets.all(12), itemCount: filtered.length, separatorBuilder: (_, __) => const SizedBox(height: 4), itemBuilder: (_, i) { final x = filtered[i]; final s = DateTime.tryParse(x['startIso'] ?? '')?.toLocal(); final e = DateTime.tryParse(x['stopIso'] ?? '')?.toLocal(); return Card(child: ListTile(leading: Icon(x['state'] == 'now' ? Icons.play_circle : Icons.schedule), title: Text(x['title'] ?? ''), subtitle: Text(s == null || e == null ? '' : TimeOfDay.fromDateTime(s).format(ctx) + ' — ' + TimeOfDay.fromDateTime(e).format(ctx)), onTap: () { Navigator.pop(ctx); play(channel); })); })),
      ])));
    }));
  }

  Future<void> _showEpgTimeline() async {
    if (playing == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شغّل قناة أولاً لعرض الخط الزمني.'))); return; }
    final channel = playing!;
    final items = await AurenTvService.instance.smartScheduleForChannel(channel, source: activeSource, hours: 48);
    if (!mounted) return;
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(child: SizedBox(height: MediaQuery.of(ctx).size.height * .72, child: Column(children: [
      ListTile(title: Text('Live EPG Timeline • ' + channel.name), subtitle: const Text('البرنامج الحالي والقادم')),
      Expanded(child: ListView.separated(padding: const EdgeInsets.all(12), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 5), itemBuilder: (_, i) { final x = items[i]; final s = DateTime.tryParse(x['startIso'] ?? '')?.toLocal(); final e = DateTime.tryParse(x['stopIso'] ?? '')?.toLocal(); final now = DateTime.now(); final progress = s == null || e == null || !e.isAfter(s) ? 0.0 : now.isBefore(s) ? 0.0 : now.isAfter(e) ? 1.0 : now.difference(s).inMilliseconds / e.difference(s).inMilliseconds; return Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(x['state'] == 'now' ? Icons.play_circle : Icons.schedule), const SizedBox(width: 8), Expanded(child: Text(x['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700))), if (s != null) Text(TimeOfDay.fromDateTime(s).format(ctx))]), const SizedBox(height: 8), LinearProgressIndicator(value: progress.clamp(0.0, 1.0))]))); })),
    ]))));
  }
  Future<void> _showEpgWatchlist() async {
    final items = await AurenTvService.instance.watchlistPrograms();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .72,
          child: items.isEmpty
              ? const Center(child: Text('لا توجد برامج محفوظة بعد.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return const ListTile(
                        title: Text('برامجي المحفوظة • EPG', style: TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('اضغط على البرنامج لمشاهدته، أو احذفه من القائمة.'),
                      );
                    }
                    final x = items[i - 1];
                    final start = DateTime.tryParse(x.startIso)?.toLocal();
                    final stop = DateTime.tryParse(x.stopIso)?.toLocal();
                    final time = start == null || stop == null
                        ? x.startIso
                        : TimeOfDay.fromDateTime(start).format(ctx) + ' — ' + TimeOfDay.fromDateTime(stop).format(ctx);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(x.state == 'now' ? Icons.play_arrow : Icons.schedule)),
                        title: Text(x.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(time),
                        trailing: IconButton(
                          tooltip: 'حذف من المحفوظة',
                          onPressed: () async {
                            await AurenTvService.instance.removeEpgWatchlist(x);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              await _showEpgWatchlist();
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                        onTap: () async {
                          final channel = await AurenTvService.instance.findChannelForEpgId(x.channelId, source: activeSource);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (channel != null) {
                            await play(channel);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البرنامج محفوظ، لكن القناة غير متاحة حالياً.')));
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<bool> _hasEpgReminder(AurenTvEpgSearchResult item) async {
    final reminders = await AurenTvService.instance.epgReminders();
    return reminders.any((r) => r.channelId == item.channelId && r.startIso == item.startIso);
  }

  void _showEpgSearchResults() {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(child: SizedBox(
      height: MediaQuery.of(ctx).size.height * .72,
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerLeft, child: Text('نتائج بحث البرامج • EPG', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)))),
        Expanded(child: _epgSearching ? const Center(child: CircularProgressIndicator()) : _epgResults.isEmpty ? const Center(child: Text('ما لقينا برنامج مطابق خلال 48 ساعة.')) : ListView.separated(
          padding: const EdgeInsets.all(12), itemCount: _epgResults.length, separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final x = _epgResults[i];
            final start = DateTime.tryParse(x.startIso)?.toLocal();
            final stop = DateTime.tryParse(x.stopIso)?.toLocal();
            final time = start == null || stop == null ? '' : TimeOfDay.fromDateTime(start).format(ctx) + ' — ' + TimeOfDay.fromDateTime(stop).format(ctx);
            return Card(child: ListTile(
              leading: CircleAvatar(child: Icon(x.state == 'now' ? Icons.play_arrow : Icons.schedule)),
              title: Text(x.title),
              subtitle: Text(time),
              trailing: Wrap( children: [IconButton(tooltip: 'حفظ البرنامج', onPressed: () async { await AurenTvService.instance.addEpgWatchlist(x); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ البرنامج في EPG.'))); }, icon: const Icon(Icons.bookmark_add_outlined)), FutureBuilder<bool>(future: _hasEpgReminder(x), builder: (context, snap) => IconButton(tooltip: snap.data == true ? 'التذكير مضبوط بالفعل' : 'ضبط تذكير', onPressed: snap.data == true ? null : () async {
                  final before = await showModalBottomSheet<Duration>(context: context, builder: (sheetCtx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const ListTile(title: Text('متى تريد التذكير؟', style: TextStyle(fontWeight: FontWeight.bold))),
                    for (final m in const [5, 10, 15, 30, 60])
                      ListTile(leading: const Icon(Icons.notifications_none), title: Text('قبل $m دقيقة'), onTap: () => Navigator.pop(sheetCtx, Duration(minutes: m))),
                  ])));
                  if (before == null || !mounted) return;
                  final ok = await AurenTvService.instance.addEpgReminder(x, before: before);
                  if (ok) await _scheduleSmartStart(x);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم ضبط التذكير قبل ' + before.inMinutes.toString() + ' دقيقة.' : 'البرنامج بدأ بالفعل أو بيانات الوقت غير صالحة.')));
                }, icon: Icon(snap.data == true ? Icons.notifications_active : Icons.notifications_none)))]),
              onTap: () async {
                final channel = await AurenTvService.instance.findChannelForEpgId(x.channelId, source: activeSource);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (channel != null) {
                  await play(channel);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لقينا البرنامج لكن القناة غير متاحة حالياً.')),
                  );
                }
              },
            ));
          },
        )),
      ]),
    )));
  }

  void _smartSearch(String value) {
    final normalized = _normalizeSearch(value);
    setState(() => query = normalized);
  }

  Future<void> _showEpgAiSearch() async {
    final controller = TextEditingController();
    final prompt = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AUREN AI • EPG'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'مثال: مباراة الهلال اليوم أو فيلم أكشن',
            labelText: 'ماذا تريد أن تشاهد؟',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('بحث')),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || prompt == null || prompt.trim().length < 2) return;
    setState(() => _epgSearching = true);
    final results = await AurenTvEpgSmartService.instance.aiEpgSearch(prompt, source: activeSource);
    if (!mounted) return;
    setState(() { _epgResults = results; _epgSearching = false; });
    _showEpgSearchResults();
  }

  Future<void> _showEpgPersonalized() async {
    final channels = await AurenTvService.instance.loadAllEnabledSources(limitPerSource: 500);
    final recommendations = await AurenTvEpgSmartService.instance.personalizeChannels(channels, limit: 20);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .72,
          child: recommendations.isEmpty
              ? const Center(child: Text('شاهد بعض القنوات أولاً ليبني AUREN اقتراحاتك.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: recommendations.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    if (i == 0) return const ListTile(
                      title: Text('For You • TV', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('اقتراحات مبنية على القنوات التي شاهدتها والمفضلة لديك على هذا الجهاز.'),
                    );
                    final c = recommendations[i - 1];
                    return Card(child: ListTile(
                      leading: c.logo.isEmpty ? const CircleAvatar(child: Icon(Icons.tv)) : CircleAvatar(backgroundImage: NetworkImage(c.logo)),
                      title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${c.country} • ${c.language} • ${c.category}'),
                      onTap: () { Navigator.pop(ctx); play(c); },
                    ));
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _showEpgSmartSettings() async {
    var enabled = await AurenTvEpgSmartService.instance.smartNotificationsEnabled();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const ListTile(
              title: Text('AUREN TV • Smart EPG', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('تحكم في التنبيهات الذكية والاقتراحات على جهازك.'),
            ),
            SwitchListTile(
              title: const Text('تنبيهات بداية البرامج'),
              subtitle: const Text('يتم تشغيلها عند ضبط تذكير ذكي.'),
              value: enabled,
              onChanged: (value) async {
                await AurenTvEpgSmartService.instance.setSmartNotificationsEnabled(value);
                setLocal(() => enabled = value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('بحث AUREN AI في EPG'),
              onTap: () { Navigator.pop(ctx); _showEpgAiSearch(); },
            ),
            ListTile(
              leading: const Icon(Icons.person_search_outlined),
              title: const Text('For You • TV'),
              onTap: () { Navigator.pop(ctx); _showEpgPersonalized(); },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _scheduleSmartStart(AurenTvEpgSearchResult item) async {
    final ok = await AurenTvEpgSmartService.instance.scheduleSmartStart(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'تم تفعيل تنبيه ذكي عند بدء البرنامج.' : 'البرنامج بدأ بالفعل أو وقت البرنامج غير صالح.')),
    );
  }

  @override void dispose() {
    _watchTogetherSubscription?.cancel();
    _watchTogetherMessageSubscription?.cancel();
    _watchTogetherActivitySubscription?.cancel();
    _watchTogetherReactionSubscription?.cancel();
    _watchTogetherSyncTimer?.cancel();
    _watchTogetherPresenceTimer?.cancel();
    unawaited(AurenTvWatchTogetherService.instance.disposePushNotifications());
    if (_watchTogetherRoom != null) unawaited(AurenTvWatchTogetherService.instance.heartbeat(_watchTogetherRoom!, online: false));
    _search.dispose();
    _recoveryTimer?.cancel();
    _connectivitySubscription?.cancel();
    player?.dispose();
    super.dispose();
  }

  String _favoriteKey(AurenTvChannel c) {
    final clean = (String value) => value.toLowerCase()
        .replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه').replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^a-z0-9\\u0600-\\u06ff]+'), '');
    final tvg = clean(c.tvgId);
    return tvg.isNotEmpty ? 'tvg:$tvg' : 'name:${clean(c.name)}|country:${clean(c.country)}';
  }

  Future<void> toggleFavorite(AurenTvChannel c) async {
    final key = _favoriteKey(c);
    final value = !favorites.contains(c.id) && !favorites.contains(key);
    await AurenTvService.instance.setChannelFavorite(c, value);
    if (mounted) setState(() {
      if (value) { favorites.add(key); favorites.remove(c.id); }
      else { favorites.remove(key); favorites.remove(c.id); }
    });
  }

  Future<void> play(AurenTvChannel c, {bool syncWatchTogether = true, bool autoplay = true}) async {
    _failoverAttempts = 0;
    _bufferingSince = null;
    _lastPosition = null;
    _lastProgressAt = DateTime.now();
    final generation = ++_playerGeneration;
    if (mounted) setState(() { loading = true; });
    final resolved = await AurenTvService.instance.bestAvailableChannel(c);
    await AurenTvEpgSmartService.instance.recordChannelOpen(c);
    await AurenTvHomeService.instance.recordWatch(c);
    if (!mounted || generation != _playerGeneration) return;
    final channel = resolved ?? c;
    if (lowData) {
      // Low Data mode avoids automatic playback and keeps the player from
      // starting until the user explicitly taps Play.
      if (mounted) setState(() => loading = false);
    }
    await player?.dispose();
    if (!mounted || generation != _playerGeneration) return;
    final p = VideoPlayerController.networkUrl(Uri.parse(channel.url));
    player = p;
    playing = channel;
    if (_watchTogetherRoom != null && syncWatchTogether) {
      await AurenTvWatchTogetherService.instance.sync(_watchTogetherRoom!, channelId: channel.id, channelName: channel.name);
    }
    p.addListener(_onPlayerValueChanged);
    try {
      await p.initialize();
      if (!mounted || generation != _playerGeneration) {
        await p.dispose();
        return;
      }
      if (_bufferingSince != null) {
        _totalBuffering += DateTime.now().difference(_bufferingSince!);
        _bufferEvents++;
      }
      _bufferingSince = null;
      _lastPosition = p.value.position;
      _lastProgressAt = DateTime.now();
      setState(() { loading = false; });
      if (autoplay && !lowData) await p.play();
    } catch (_) {
      if (!mounted || generation != _playerGeneration) return;
      setState(() { loading = false; });
      await _recoverPlayback(reason: 'تعذر تشغيل البث');
    }
  }

  void _onPlayerValueChanged() {
    final p = player;
    if (!mounted || p == null || !p.value.isInitialized) return;
    final value = p.value;
    if (value.hasError) {
      _recoverPlayback(reason: 'انقطع البث');
      return;
    }
    if (!value.isBuffering) {
      _bufferingSince = null;
      if (_lastPosition == null || value.position != _lastPosition) {
        _lastPosition = value.position;
        _lastProgressAt = DateTime.now();
      }
    } else {
      _bufferingSince ??= DateTime.now();
    }
  }

  void _monitorPlayback() {
    final p = player;
    if (!mounted || p == null || !p.value.isInitialized || _recovering) return;
    if (!_networkAvailable) return;
    final value = p.value;
    if (value.hasError) {
      _recoverPlayback(reason: 'انقطع البث');
      return;
    }
    if (value.isBuffering) {
      _bufferingSince ??= DateTime.now();
      final bufferingFor = DateTime.now().difference(_bufferingSince!);
      // Adaptive buffering: tolerate short mobile-network stalls, then recover.
      final threshold = lowData ? const Duration(seconds: 12) : const Duration(seconds: 8);
      if (bufferingFor >= threshold && DateTime.now().difference(_lastRecoveryAt ?? DateTime.fromMillisecondsSinceEpoch(0)) >= const Duration(seconds: 15)) {
        _recoverPlayback(reason: 'البث متوقف مؤقتاً');
      }
      return;
    }
    if (value.isPlaying) {
      _lastPosition ??= value.position;
      _lastProgressAt ??= DateTime.now();
      if (value.position != _lastPosition) {
        _lastPosition = value.position;
        _lastProgressAt = DateTime.now();
      } else if (DateTime.now().difference(_lastProgressAt!) >= const Duration(seconds: 12)) {
        _recoverPlayback(reason: 'البث لا يتقدم');
      }
    }
  }

  Future<List<AurenTvChannel>> _recoveryCandidates(AurenTvChannel current) async {
    final identity = AurenTvService.channelIdentity(current);
    final result = <AurenTvChannel>[];
    final seen = <String>{};
    for (final source in (await AurenTvService.instance.sources()).where((x) => x.enabled)) {
      try {
        final channels = await AurenTvService.instance.loadSource(source, limit: 500);
        for (final candidate in channels) {
          if (AurenTvService.channelIdentity(candidate) != identity) continue;
          if (candidate.url == current.url) continue;
          if (!seen.add(candidate.url)) continue;
          result.add(candidate);
        }
      } catch (_) {}
    }
    result.sort((a, b) {
      int score(AurenTvChannel c) =>
          (c.url.startsWith('https://') ? 2 : 0) +
          (c.tvgId.isNotEmpty ? 2 : 0) +
          (c.logo.isNotEmpty ? 1 : 0);
      return score(b).compareTo(score(a));
    });
    return result;
  }

  Future<void> _recoverPlayback({required String reason}) async {
    if (!mounted || _recovering || playing == null) return;
    if (_failoverAttempts >= _maxFailoverAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر استعادة البث تلقائياً. يمكنك اختيار القناة مرة أخرى.')),
      );
      return;
    }
    _recovering = true;
    _lastRecoveryAt = DateTime.now();
    _failoverAttempts++;
    final generation = ++_playerGeneration;
    final current = playing!;
    _bufferingSince = null;
    _lastPosition = null;
    _lastProgressAt = DateTime.now();
    try {
      final candidates = await _recoveryCandidates(current);
      if (!mounted || generation != _playerGeneration) return;
      final ranked = <AurenTvChannel>[];
      for (final candidate in candidates) {
        final health = await AurenTvService.instance.checkChannelHealth(
          candidate,
          timeout: const Duration(seconds: 4),
        );
        if (health.status == 'online') ranked.add(candidate);
      }
      if (ranked.isEmpty) ranked.addAll(candidates);
      for (final candidate in ranked) {
        if (!mounted || generation != _playerGeneration) return;
        final old = player;
        player = null;
        await old?.dispose();
        final next = VideoPlayerController.networkUrl(Uri.parse(candidate.url));
        player = next;
        playing = candidate;
        next.addListener(_onPlayerValueChanged);
        try {
          await next.initialize();
          if (!mounted || generation != _playerGeneration) {
            await next.dispose();
            return;
          }
          if (_bufferingSince != null) {
            _totalBuffering += DateTime.now().difference(_bufferingSince!);
            _bufferEvents++;
          }
          _bufferingSince = null;
          _lastPosition = next.value.position;
          _lastProgressAt = DateTime.now();
          setState(() { loading = false; });
          if (!lowData) await next.play();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم استعادة البث تلقائياً عبر مصدر بديل.')),
          );
          return;
        } catch (_) {
          await next.dispose();
        }
      }
      if (mounted) {
        setState(() { loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$reason؛ لم يتوفر مصدر بديل صالح حالياً.')),
        );
      }
    } finally {
      _recovering = false;
    }
  }
  Future<void> _pickCountry() async {
    final countries = <String, String>{
      'SD': 'السودان 🇸🇩', 'EG': 'مصر 🇪🇬', 'SA': 'السعودية 🇸🇦', 'AE': 'الإمارات 🇦🇪',
      'QA': 'قطر 🇶🇦', 'KW': 'الكويت 🇰🇼', 'BH': 'البحرين 🇧🇭', 'OM': 'عُمان 🇴🇲',
      'JO': 'الأردن 🇯🇴', 'IQ': 'العراق 🇮🇶', 'LB': 'لبنان 🇱🇧', 'MA': 'المغرب 🇲🇦',
      'DZ': 'الجزائر 🇩🇿', 'TN': 'تونس 🇹🇳', 'TR': 'تركيا 🇹🇷', 'ZA': 'جنوب أفريقيا 🇿🇦',
      'NG': 'نيجيريا 🇳🇬', 'KE': 'كينيا 🇰🇪', 'IN': 'الهند 🇮🇳', 'CN': 'الصين 🇨🇳',
      'JP': 'اليابان 🇯🇵', 'KR': 'كوريا الجنوبية 🇰🇷', 'GB': 'بريطانيا 🇬🇧', 'FR': 'فرنسا 🇫🇷',
      'DE': 'ألمانيا 🇩🇪', 'IT': 'إيطاليا 🇮🇹', 'ES': 'إسبانيا 🇪🇸', 'US': 'الولايات المتحدة 🇺🇸',
      'CA': 'كندا 🇨🇦', 'BR': 'البرازيل 🇧🇷', 'AU': 'أستراليا 🇦🇺',
    };
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('اختر دولة', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('يمكنك أيضاً استخدام البحث لاسم قناة أو لغة أو فئة.'),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('كل الدول'),
              selected: country.isEmpty && continent.isEmpty && quickRegion.isEmpty,
              onTap: () => Navigator.pop(ctx, ''),
            ),
            ...countries.entries.map((entry) => ListTile(
              leading: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              title: Text(entry.value),
              selected: country == entry.key,
              onTap: () => Navigator.pop(ctx, entry.key),
            )),
          ],
        ),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      country = picked;
      countryLabel = picked.isEmpty ? 'الدول' : (countries[picked] ?? picked);
      continent = '';
      quickRegion = '';
    });
  }

  Future<void> _showSchedule(AurenTvChannel channel) async {
    final items = activeSource != null
        ? await AurenTvService.instance.scheduleForSourceChannel(activeSource!, channel, hours: 24)
        : await AurenTvService.instance.scheduleForChannel(channel, hours: 24);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .72,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              if (channel.logo.isNotEmpty) CircleAvatar(backgroundImage: NetworkImage(channel.logo)),
              const SizedBox(width: 10),
              Expanded(child: Text(channel.name + ' • EPG', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
            ])),
            const Divider(height: 1),
            if (items.isEmpty) const Expanded(child: Center(child: Text('دليل البرامج غير متاح لهذه القناة حالياً.')))
            else Expanded(child: ListView.separated(
              padding: const EdgeInsets.all(12), itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final x = items[i];
                final start = DateTime.tryParse(x['startIso'] ?? '')?.toLocal();
                final stop = DateTime.tryParse(x['stopIso'] ?? '')?.toLocal();
                final time = start == null || stop == null ? '' : '${TimeOfDay.fromDateTime(start).format(ctx)} — ${TimeOfDay.fromDateTime(stop).format(ctx)}';
                final isNow = x['state'] == 'now';
                return Card(child: ListTile(leading: CircleAvatar(child: Icon(isNow ? Icons.play_arrow : Icons.schedule)), title: Text(x['title'] ?? 'برنامج'), subtitle: Text(time), trailing: isNow ? const Chip(label: Text('الآن')) : null));
              },
            )),
          ]),
        ),
      ),
    );
  }


  Future<void> _checkChannel(AurenTvChannel channel) async {
    final health = await AurenTvService.instance.checkChannelHealth(channel);
    if (!mounted) return;
    final detail = health.latencyMs == null ? health.status : '${health.status} • ${health.latencyMs}ms';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حالة ${channel.name}: $detail')));
  }

  Future<void> _testSource(AurenTvSource source) async {
    try {
      final count = await AurenTvService.instance.testSource(source);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الاتصال ناجح • $count قناة متاحة')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل اختبار الاتصال: $e')));
    }
  }

  Future<void> _toggleSource(AurenTvSource source) async {
    final enabled = !source.enabled;
    await AurenTvService.instance.setSourceEnabled(source.id, enabled);
    if (!mounted) return;
    final updated = AurenTvSource(id: source.id, name: source.name, type: source.type, url: source.url, epgUrl: source.epgUrl, username: source.username, password: source.password, enabled: enabled);
    setState(() {
      sources = sources.map((x) => x.id == source.id ? updated : x).toList();
      if (!enabled && activeSource?.id == source.id) activeSource = null;
    });
  }

  Future<void> _makeDefault(AurenTvSource source) async {
    await AurenTvService.instance.setDefaultSource(source.id);
    if (!mounted) return;
    setState(() => activeSource = source);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعيين المصدر الافتراضي.')));
  }

  Future<void> _showSources() async {
    final choice = await showModalBottomSheet<String>(
      context: context, showDragHandle: true,
      builder: (ctx) => SafeArea(child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const ListTile(title: Text('مصادر IPTV الخاصة بي', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('أضف M3U أو Xtream من اشتراك تملكه أو لديك حق استخدامه.')),
          ListTile(leading: const Icon(Icons.add_link), title: const Text('إضافة مصدر'), onTap: () => Navigator.pop(ctx, '__add__')),
          ...sources.map((source) => ListTile(
            leading: Icon(source.type == 'xtream' ? Icons.cloud : Icons.link),
            title: Text(source.name),
            subtitle: Text('${source.type == 'xtream' ? 'Xtream' : 'M3U'} • ${source.enabled ? 'مفعّل' : 'متوقف'}${activeSource?.id == source.id ? ' • نشط' : ''}'),
            trailing: Wrap( children: [
              IconButton(tooltip: 'اختبار الاتصال', icon: const Icon(Icons.network_check), onPressed: source.enabled ? () => _testSource(source) : null),
              IconButton(tooltip: source.enabled ? 'تعطيل المصدر' : 'تفعيل المصدر', icon: Icon(source.enabled ? Icons.toggle_on : Icons.toggle_off), onPressed: () => _toggleSource(source)),
              IconButton(tooltip: 'جعله افتراضي', icon: const Icon(Icons.star_border), onPressed: source.enabled ? () => _makeDefault(source) : null),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
                await AurenTvService.instance.deleteSource(source.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {
                  sources = sources.where((x) => x.id != source.id).toList();
                  if (activeSource?.id == source.id) activeSource = null;
                });
              }),
            ]),
            onTap: source.enabled ? () => Navigator.pop(ctx, source.id) : null,
          )),
        ],
      )),
    );
    if (!mounted || choice == null) return;
    if (choice == '__add__') { await _addSource(); return; }
    final matches = sources.where((x) => x.id == choice).toList();
    final selected = matches.isEmpty ? null : matches.first;
    if (selected == null || !selected.enabled) return;
    setState(() { activeSource = selected; tvMode = 'world'; country = ''; continent = ''; quickRegion = ''; });
  }

  Future<void> _addSource() async {
    String type = 'm3u';
    final name = TextEditingController(text: 'IPTV الخاص بي');
    final url = TextEditingController();
    final epg = TextEditingController();
    final user = TextEditingController();
    final pass = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
      title: const Text('إضافة مصدر IPTV'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'النوع'), items: const [DropdownMenuItem(value: 'm3u', child: Text('M3U URL')), DropdownMenuItem(value: 'xtream', child: Text('Xtream API'))], onChanged: (v) => setLocal(() => type = v ?? 'm3u')),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المصدر')),
        TextField(controller: url, decoration: InputDecoration(labelText: type == 'xtream' ? 'رابط السيرفر / Base URL' : 'رابط M3U'), keyboardType: TextInputType.url),
        if (type == 'xtream') ...[TextField(controller: user, decoration: const InputDecoration(labelText: 'Username')), TextField(controller: pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true)],
        TextField(controller: epg, decoration: const InputDecoration(labelText: 'EPG URL (اختياري)'), keyboardType: TextInputType.url),
        const SizedBox(height: 8), const Text('بيانات الدخول تُحفظ محلياً في التخزين الآمن للجهاز.', style: TextStyle(fontSize: 12)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))],
    )));
    if (ok != true) { name.dispose(); url.dispose(); epg.dispose(); user.dispose(); pass.dispose(); return; }
    final source = AurenTvSource(id: 'src-${DateTime.now().microsecondsSinceEpoch}', name: name.text.trim().isEmpty ? 'IPTV الخاص بي' : name.text.trim(), type: type, url: url.text.trim(), epgUrl: epg.text.trim(), username: user.text.trim(), password: pass.text);
    await AurenTvService.instance.saveSource(source);
    await AurenTvService.instance.setDefaultSource(source.id);
    if (mounted) setState(() { sources = [...sources, source]; activeSource = source; });
    name.dispose(); url.dispose(); epg.dispose(); user.dispose(); pass.dispose();
  }
  String _normalizeSearch(String value) {
    return value.toLowerCase()
        .replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه').replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[ًٌٍَُِّْـ]'), '')
        .replaceAll(RegExp(r'[^a-z0-9A-Za-z0-9\u0600-\u06ff ]+'), ' ')
        .trim();
  }

  String _regionLabel(AurenTvChannel c) {
    final code = c.country.toUpperCase();
    for (final entry in regions.entries) { if (entry.value.contains(code)) return entry.key; }
    return 'Other';
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN TV'), actions: [
      IconButton(tooltip: 'برامجي المحفوظة', onPressed: _showEpgWatchlist, icon: const Icon(Icons.bookmarks_outlined)), IconButton(tooltip: 'تذكيرات EPG', onPressed: _showEpgReminderCenter, icon: const Icon(Icons.notifications_none)), IconButton(tooltip: 'تقويم EPG', onPressed: _showEpgCalendar, icon: const Icon(Icons.calendar_month_outlined)), IconButton(tooltip: 'خط EPG الزمني', onPressed: _showEpgTimeline, icon: const Icon(Icons.timeline)), IconButton(tooltip: 'AUREN AI • EPG', onPressed: _showEpgAiSearch, icon: const Icon(Icons.auto_awesome)), IconButton(tooltip: 'For You • TV', onPressed: _showEpgPersonalized, icon: const Icon(Icons.person_search_outlined)), IconButton(tooltip: 'Smart EPG', onPressed: _showEpgSmartSettings, icon: const Icon(Icons.tune)), IconButton(tooltip: 'TV Home • For You', onPressed: _showTvHome, icon: const Icon(Icons.home_work_outlined)), IconButton(tooltip: 'Multi-Channel EPG', onPressed: _showMultiChannelEpg, icon: const Icon(Icons.view_agenda_outlined)), IconButton(tooltip: 'TV Profiles', onPressed: _showTvProfiles, icon: const Icon(Icons.account_circle_outlined)), IconButton(tooltip: 'Watch Together', onPressed: _showWatchTogether, icon: const Icon(Icons.groups_outlined)), if (playing != null) IconButton(tooltip: 'Mini Player', onPressed: _togglePip, icon: Icon(_pipMode ? Icons.picture_in_picture : Icons.picture_in_picture_alt_outlined)),
      IconButton(tooltip: 'مصادر IPTV الخاصة بي', onPressed: _showSources, icon: const Icon(Icons.link)),
      if (activeSource != null)
        IconButton(
          tooltip: 'تحديث مصدر IPTV',
          onPressed: () async {
            try {
              await AurenTvService.instance.refreshSource(activeSource!, limit: lowData ? 150 : 500);
              await AurenTvService.instance.refreshEpgAndSyncReminders(source: activeSource);
              if (mounted) setState(() {});
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تعذر تحديث مصدر IPTV حالياً.')),
              );
            }
          },
          icon: const Icon(Icons.refresh),
        ),
    ]),
    body: Stack(children: [
      Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
        child: SizedBox(
          height: 50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(segments: const [
        ButtonSegment(value: 'world', label: Text('العالم'), icon: Icon(Icons.public)),
        ButtonSegment(value: 'entertainment', label: Text('ترفيه'), icon: Icon(Icons.movie_outlined)),
        ButtonSegment(value: 'sports', label: Text('رياضة'), icon: Icon(Icons.sports_soccer)),
        ButtonSegment(value: 'news', label: Text('أخبار'), icon: Icon(Icons.newspaper)),
        ButtonSegment(value: 'movies', label: Text('أفلام'), icon: Icon(Icons.local_movies_outlined)),
        ButtonSegment(value: 'music', label: Text('موسيقى'), icon: Icon(Icons.music_note)),
        ButtonSegment(value: 'kids', label: Text('أطفال'), icon: Icon(Icons.child_care)),
        ButtonSegment(value: 'animation', label: Text('أنمي/كرتون'), icon: Icon(Icons.animation)),
        ButtonSegment(value: 'documentary', label: Text('وثائقي'), icon: Icon(Icons.menu_book_outlined)),
        ButtonSegment(value: 'series', label: Text('مسلسلات'), icon: Icon(Icons.tv_outlined)),
      ], selected: {tvMode}, onSelectionChanged: (v) => setState(() { tvMode = v.first; country = ''; continent = ''; quickRegion = ''; category = ''; newsRegion = 'all'; sportCategory = 'all'; entertainmentCategory = 'all'; })),
          ),
        ),
      ),
      if (activeSource != null) Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Align(alignment: AlignmentDirectional.centerStart, child: Chip(
          avatar: Icon(activeSource!.type == 'xtream' ? Icons.cloud : Icons.link, size: 18),
          label: Text('المصدر: ' + activeSource!.name),
          onDeleted: () => setState(() => activeSource = null),
        )),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: TextField(
          controller: _search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'ابحث بذكاء: قناة، دولة، لغة أو فئة',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'بحث في دليل البرامج EPG',
                  onPressed: _search.text.trim().length < 2 ? null : () async {
                    await _searchEpg();
                    if (mounted) _showEpgSearchResults();
                  },
                  icon: _epgSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.event_note_outlined),
                ),
                if (query.isNotEmpty)
                  IconButton(onPressed: () { _search.clear(); setState(() => query = ''); }, icon: const Icon(Icons.clear)),
            ],
            ),
          ),
          onChanged: (v) => setState(() { query = _normalizeSearch(v); }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _pickCountry, icon: const Icon(Icons.public), label: Text(countryLabel), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
          const SizedBox(width: 8),
          Expanded(child: TextField(decoration: const InputDecoration(labelText: 'الفئة'), onChanged: (v) => setState(() => category = v))),
        ]),
      ),
      if (tvMode == 'sports' || tvMode == 'entertainment')
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final item in (tvMode == 'sports'
                  ? const [['all', 'كل الرياضات'], ['football', '⚽ كرة القدم'], ['basketball', '🏀 كرة السلة'], ['tennis', '🎾 التنس'], ['motorsport', '🏎️ سباقات'], ['combat', '🥊 قتال'], ['golf', '🏌️ غولف'], ['other', '🏆 أخرى']]
                  : const [['all', 'كل الترفيه'], ['movies', '🎬 أفلام'], ['series', '📺 مسلسلات'], ['comedy', '😂 كوميديا'], ['music', '🎵 موسيقى'], ['kids', '👶 أطفال'], ['animation', '🎨 أنمي/كرتون'], ['culture', '🌍 ثقافة'], ['documentary', '📚 وثائقي']]))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(item[1]),
                    selected: (tvMode == 'sports' ? sportCategory : entertainmentCategory) == item[0],
                    onSelected: (_) => setState(() {
                      if (tvMode == 'sports') { sportCategory = item[0]; } else { entertainmentCategory = item[0]; }
                      category = '';
                    }),
                  ),
                ),
            ],
          ),
        ),
      if (tvMode == 'news')
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final item in const [
                ['all', 'كل الأخبار'],
                ['SD', '🇸🇩 السودان'],
                ['Arab', '🌙 عربي'],
                ['Africa', '🌍 أفريقيا'],
                ['World', '🌐 عالمي'],
                ['Business', '💼 اقتصاد'],
                ['Sports', '⚽ أخبار الرياضة'],
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(item[1]),
                    selected: newsRegion == item[0],
                    onSelected: (_) => setState(() {
                      newsRegion = item[0];
                      country = '';
                      continent = '';
                      quickRegion = '';
                    }),
                  ),
                ),
            ],
          ),
        ),
      SizedBox(height: 42, child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: const Text('🇸🇩 السودان'), selected: quickRegion == 'Sudan', onSelected: (_) => setState(() { quickRegion = quickRegion == 'Sudan' ? '' : 'Sudan'; country = quickRegion == 'Sudan' ? 'SD' : ''; continent = ''; }))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: const Text('🌍 عربي'), selected: quickRegion == 'Arab', onSelected: (_) => setState(() { quickRegion = quickRegion == 'Arab' ? '' : 'Arab'; country = ''; continent = ''; }))),
          for (final region in regions.keys)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: Text(region), selected: continent == region, onSelected: (_) => setState(() { continent = continent == region ? '' : region; country = ''; quickRegion = ''; }))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: FilterChip(
            label: const Text('المفضلة'), selected: onlyFavorites, onSelected: (v) => setState(() => onlyFavorites = v),
          )),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: FilterChip(
            label: const Text('Low Data'), selected: lowData, onSelected: (v) => setState(() => lowData = v),
          )),
        ],
      )),
      if (playing != null && _bufferEvents > 0)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Align(alignment: AlignmentDirectional.centerStart, child: Text('Smart Buffer • $_bufferEvents توقف • ${_totalBuffering.inSeconds}s', style: const TextStyle(fontSize: 11))),
        ),
      if (lowData) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          const Icon(Icons.data_saver_on, size: 16), const SizedBox(width: 6),
          Expanded(child: Text(autoLowData ? 'Low Data تلقائي • ${_connectionType == ConnectivityResult.mobile ? 'بيانات الهاتف' : 'اتصال محدود'} • التشغيل يبدأ عند الطلب' : 'Low Data • التشغيل يبدأ عند الطلب', style: const TextStyle(fontSize: 12))),
          TextButton(onPressed: () => setState(() => autoLowData = !autoLowData), child: Text(autoLowData ? 'يدوي' : 'تلقائي')),
        ]),
      ),
      if (!_networkAvailable)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [Icon(Icons.wifi_off, size: 16), SizedBox(width: 6), Text('لا يوجد اتصال بالإنترنت حالياً.')]),
        ),
      if (loading) const LinearProgressIndicator(),
      if (player?.value.isInitialized == true && !_pipMode)
        Column(children: [
          AspectRatio(aspectRatio: player!.value.aspectRatio, child: VideoPlayer(player!)),
          Row(children: [
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(playing?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis))),
            IconButton(onPressed: () async {
              if (player!.value.isPlaying) {
                await player!.pause();
              } else {
                await player!.play();
              }
              if (_watchTogetherRoom != null && player != null) {
                await AurenTvWatchTogetherService.instance.sync(_watchTogetherRoom!, positionSeconds: player!.value.position.inMilliseconds / 1000.0, isPlaying: player!.value.isPlaying);
              }
              if (mounted) setState(() {});
            }, icon: Icon(player!.value.isPlaying ? Icons.pause : Icons.play_arrow)),
          ]),
          if (playing != null)
            FutureBuilder<Map<String, String>?>(
              future: AurenTvService.instance.nowNextForChannel(playing!, source: activeSource),
              builder: (context, snapshot) {
                final guide = snapshot.data;
                if (guide == null) return const Padding(padding: EdgeInsets.all(6), child: Text('دليل البرامج غير متاح لهذه القناة حالياً.'));
                return Card(margin: const EdgeInsets.fromLTRB(12, 2, 12, 8), child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('دليل البرامج • EPG', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('الآن: ${(guide['current'] ?? '').isEmpty ? 'غير متاح' : guide['current']}'),
                    Text('القادم: ${(guide['next'] ?? '').isEmpty ? 'غير متاح' : guide['next']}'),
                    if ((guide['currentStart'] ?? '').isNotEmpty && (guide['currentStop'] ?? '').isNotEmpty) Builder(builder: (_) {
                      final start = DateTime.tryParse(guide['currentStart']!)?.toLocal();
                      final stop = DateTime.tryParse(guide['currentStop']!)?.toLocal();
                      if (start == null || stop == null || !stop.isAfter(start)) return const SizedBox.shrink();
                      final now = DateTime.now();
                      final progress = now.isBefore(start) ? 0.0 : now.isAfter(stop) ? 1.0 : now.difference(start).inMilliseconds / stop.difference(start).inMilliseconds;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0))),
                      );
                    }),
                  ]),
                ));
              },
            ),
        ]),
      Expanded(child: FutureBuilder<List<AurenTvChannel>>(
        future: activeSource != null ? AurenTvService.instance.loadSource(activeSource!, limit: lowData ? 150 : 500) : tvMode == 'entertainment' ? AurenTvService.instance.loadEntertainment(limit: lowData ? 150 : 500) : tvMode == 'sports' ? AurenTvService.instance.loadSports(limit: lowData ? 150 : 500) : tvMode == 'news' ? AurenTvService.instance.loadNews(limit: lowData ? 150 : 500) : tvMode == 'movies' ? AurenTvService.instance.loadMovies(limit: lowData ? 150 : 500) : tvMode == 'music' ? AurenTvService.instance.loadMusic(limit: lowData ? 150 : 500) : tvMode == 'kids' ? AurenTvService.instance.loadKids(limit: lowData ? 150 : 500) : tvMode == 'animation' ? AurenTvService.instance.loadAnimation(limit: lowData ? 150 : 500) : tvMode == 'documentary' ? AurenTvService.instance.loadDocumentary(limit: lowData ? 150 : 500) : tvMode == 'series' ? AurenTvService.instance.loadSeries(limit: lowData ? 150 : 500) : continent.isNotEmpty ? AurenTvService.instance.loadFeaturedByCountries(regions[continent]!.toSet(), limit: 20) : AurenTvService.instance.load(country: country, category: category),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل القنوات: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final arabCountries = {'DZ','BH','KM','DJ','EG','IQ','JO','KW','LB','LY','MR','MA','OM','PS','QA','SA','SO','SD','SY','TN','AE','YE'};
          final maxChannels = lowData ? 150 : 500;
          final channels = snapshot.data!.where((c) {
            final searchable = _normalizeSearch('${c.name} ${c.country} ${c.language} ${c.category}');
            final searchableTokens = searchable.split(RegExp(r'\\s+')).where((x) => x.isNotEmpty).toList();
            final matchesQuery = query.isEmpty || searchable.contains(query) || query.split(RegExp(r'\\s+')).every((q) => searchableTokens.any((token) => token.contains(q) || q.contains(token)));
            final matchesRegion = continent.isEmpty || _regionLabel(c) == continent;
            final n = '${c.name} ${c.category} ${c.language} ${c.country}'.toLowerCase();
            final matchesNewsRegion = tvMode != 'news' || newsRegion == 'all' || (newsRegion == 'SD' && c.country.toUpperCase() == 'SD') || (newsRegion == 'Arab' && arabCountries.contains(c.country.toUpperCase())) || (newsRegion == 'Africa' && _regionLabel(c) == 'Africa') || (newsRegion == 'World' && _regionLabel(c) != 'Africa' && !arabCountries.contains(c.country.toUpperCase())) || (newsRegion == 'Business' && RegExp(r'business|finance|economy|market|money', caseSensitive: false).hasMatch(n)) || (newsRegion == 'Sports' && RegExp(r'sport|football|soccer|basketball|tennis|espn', caseSensitive: false).hasMatch(n));
            final matchesQuick = quickRegion == 'Sudan' ? c.country.toUpperCase() == 'SD' : quickRegion == 'Arab' ? arabCountries.contains(c.country.toUpperCase()) : true;
            final sportText = n;
            final matchesSportCategory = tvMode != 'sports' || sportCategory == 'all' ||
              (sportCategory == 'football' && RegExp(r'football|soccer|fifa|uefa|premier|league|cup', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'basketball' && RegExp(r'basketball|nba|fiba', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'tennis' && RegExp(r'tennis|atp|wta', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'motorsport' && RegExp(r'formula|f1|motorsport|nascar|racing|motogp', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'combat' && RegExp(r'boxing|mma|ufc|wrestling|fight', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'golf' && RegExp(r'golf', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'other' && !RegExp(r'football|soccer|basketball|tennis|formula|f1|motorsport|nascar|racing|motogp|boxing|mma|ufc|wrestling|fight|golf', caseSensitive: false).hasMatch(sportText));
            final matchesEntertainmentCategory = tvMode != 'entertainment' || entertainmentCategory == 'all' ||
              (entertainmentCategory == 'movies' && RegExp(r'movie|film|cinema', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'series' && RegExp(r'series|serial|drama|soap', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'comedy' && RegExp(r'comedy|humor|funny', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'music' && RegExp(r'music|musical|mtv|vh1', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'kids' && RegExp(r'kids|children|nickelodeon|cartoon', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'animation' && RegExp(r'anime|animation|cartoon', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'culture' && RegExp(r'culture|cultural|travel', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'documentary' && RegExp(r'documentary|documentaries', caseSensitive: false).hasMatch(n));
            return matchesQuery && matchesRegion && matchesQuick && matchesNewsRegion && matchesSportCategory && matchesEntertainmentCategory && (!onlyFavorites || favorites.contains(c.id) || favorites.contains(_favoriteKey(c)));
          }).toList();
          if (channels.isEmpty) return const Center(child: Text('ما لقينا قنوات مطابقة. جرّب تغيير البحث أو الدولة.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12), itemCount: channels.take(maxChannels).length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final c = channels[i];
              return Card(child: ListTile(
                leading: c.logo.isEmpty ? const CircleAvatar(child: Icon(Icons.tv)) : CircleAvatar(backgroundImage: NetworkImage(c.logo)),
                title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${c.country} • ${c.language} • ${c.category}', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Wrap( children: [
                  IconButton(tooltip: 'جدول البرامج', onPressed: () => _showSchedule(c), icon: const Icon(Icons.calendar_month_outlined)),
                  IconButton(tooltip: (favorites.contains(c.id) || favorites.contains(_favoriteKey(c))) ? 'إزالة من المفضلة' : 'أضف للمفضلة', onPressed: () => toggleFavorite(c), icon: Icon((favorites.contains(c.id) || favorites.contains(_favoriteKey(c))) ? Icons.star : Icons.star_border)),
                ]),
                onTap: () => play(c),
              ));
            },
          );
        },
      )),
      if (_watchTogether && _watchReactionOverlay.isNotEmpty)
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: _watchReactionOverlay.asMap().entries.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: 6 + entry.key * 2.0),
              child: Text(entry.value, style: const TextStyle(fontSize: 30)),
            )).toList(),
          ),
        ),
      if (_pipMode && player?.value.isInitialized == true)
        Positioned(
          right: 12,
          bottom: 18,
          width: MediaQuery.of(context).size.width * .62,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Theme.of(context).colorScheme.surface),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AspectRatio(aspectRatio: player!.value.aspectRatio, child: VideoPlayer(player!)),
                Row(children: [
                  Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(playing?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))),
                  IconButton(tooltip: 'إغلاق Mini Player', icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _pipMode = false)),
                  IconButton(icon: Icon(player!.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 20), onPressed: () async { if (player!.value.isPlaying) { await player!.pause(); } else if (!lowData) { await player!.play(); } if (_watchTogetherRoom != null) await AurenTvWatchTogetherService.instance.sync(_watchTogetherRoom!, positionSeconds: player!.value.position.inMilliseconds / 1000.0, isPlaying: player!.value.isPlaying); if (mounted) setState(() {}); }),
      ]),
    ]),
            ),
          ),
        ),
    ],
  );
}