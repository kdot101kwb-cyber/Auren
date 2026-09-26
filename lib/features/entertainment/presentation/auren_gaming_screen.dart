import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AurenGamingScreen extends StatefulWidget {
  const AurenGamingScreen({super.key});
  @override State<AurenGamingScreen> createState() => _AurenGamingScreenState();
}

class _AurenGamingScreenState extends State<AurenGamingScreen> {
  final _service = AurenGamingService();
  final _codeController = TextEditingController();
  String? _roomId;
  String? _inviteCode;
  bool _busy = false;
  int _xp = 0;
  int _wins = 0;
  int _games = 0;
  int _seasonXp = 0;
  bool _loadedStats = false;
  final _chatController = TextEditingController();
  final _friendUidController = TextEditingController();
  final _friendSearchController = TextEditingController();
  String _friendSearch = '';

  @override void initState() { super.initState(); _loadStats(); }

  @override void dispose() { _codeController.dispose(); _chatController.dispose(); _friendUidController.dispose(); _friendSearchController.dispose(); super.dispose(); }

  Future<void> _createRoom() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final room = await _service.createTicTacToeRoom(uid);
      if (!mounted) return;
      setState(() { _roomId = room.id; _inviteCode = room.inviteCode; });
    } catch (_) { if (mounted) _snack('تعذر إنشاء الغرفة.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _joinRoom() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = _codeController.text.trim().toUpperCase();
    if (uid == null || code.length != 6) return;
    setState(() => _busy = true);
    try {
      final room = await _service.joinTicTacToeRoom(uid, code);
      if (!mounted) return;
      setState(() { _roomId = room.id; _inviteCode = room.inviteCode; });
    } catch (_) { if (mounted) _snack('تعذر الانضمام. تأكد من رمز الغرفة.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _play(int index, Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_roomId == null || uid == null) return;
    final board = List<String>.from((data['board'] as List<dynamic>? ?? const []).map((e) => e.toString()));
    if (board.length != 9 || board[index].isNotEmpty || data['winner'] != null || data['draw'] == true) return;
    final players = List<String>.from((data['playerUids'] as List<dynamic>? ?? const []).map((e) => e.toString()));
    final marks = data['marks'] is Map ? Map<String, dynamic>.from(data['marks'] as Map) : <String, dynamic>{};
    if (!players.contains(uid) || players.length < 2 || data['turnUid']?.toString() != uid) return;
    final mark = marks[uid]?.toString();
    if (mark == null) return;
    board[index] = mark;
    final winner = _winner(board);
    final draw = winner == null && board.every((e) => e.isNotEmpty);
    final nextUid = winner != null || draw ? '' : players.firstWhere((p) => p != uid, orElse: () => uid);
    try {
      await _service.playMove(roomId: _roomId!, board: board, winner: winner, draw: draw, nextUid: nextUid);
      if (winner != null || draw) {
        await _service.recordResult(uid, _roomId!, winner == mark, draw);
        if (mounted) await _loadStats();
      }
    } catch (_) { if (mounted) _snack('تعذر تسجيل الحركة.'); }
  }

  String? _winner(List<String> b) {
    const lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
    for (final l in lines) {
      if (b[l[0]].isNotEmpty && b[l[0]] == b[l[1]] && b[l[1]] == b[l[2]]) return b[l[0]];
    }
    return null;
  }

  Future<void> _claimDailyChallenge(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final players = List<String>.from((data['playerUids'] as List<dynamic>? ?? const []).map((e) => e.toString()));
    final finished = data['winner'] != null || data['draw'] == true;
    if (!players.contains(uid) || !finished) {
      _snack('أكمل مباراة أولاً ثم احصل على XP.');
      return;
    }
    try {
      final result = await _service.claimDailyChallenge(uid);
      if (!mounted) return;
      if (result) {
        setState(() => _xp += 25);
        _snack('🎉 حصلت على 25 XP! الإنجاز اليومي اكتمل.');
      } else {
        _snack('تم استلام تحدي اليوم مسبقاً.');
      }
    } catch (_) {
      if (mounted) _snack('تعذر تسجيل التحدي.');
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _loadStats() async {
    if (_loadedStats) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final stats = await _service.getStats(uid);
    if (!mounted) return;
    setState(() { _xp = stats.xp; _wins = stats.wins; _games = stats.games; _seasonXp = stats.seasonXp; _loadedStats = true; });
  }

  @override Widget build(BuildContext context) {
    _loadStats();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Gaming')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _hero(context), const SizedBox(height: 12),
        _statsCard(), const SizedBox(height: 12),
        _seasonCard(), const SizedBox(height: 12),
        _achievementsCard(), const SizedBox(height: 12),
        _leaderboardCard(), const SizedBox(height: 12),
        if (_roomId == null) ...[_incomingChallengesCard(), const SizedBox(height: 12), _outgoingChallengesCard(), const SizedBox(height: 12)],
        if (_roomId == null) ...[
          _gameCard(context, Icons.grid_3x3_rounded, 'Tic-Tac-Toe',
            'لعبة سريعة لشخصين — العب مع صديق برمز دعوة.',
            FilledButton.icon(onPressed: _busy ? null : _createRoom, icon: const Icon(Icons.add), label: const Text('إنشاء غرفة'))),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            const Text('عندك رمز غرفة؟', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(controller: _codeController, textCapitalization: TextCapitalization.characters, maxLength: 6,
              decoration: const InputDecoration(labelText: 'رمز الدعوة', hintText: 'ABC123', border: OutlineInputBorder())),
            FilledButton.icon(onPressed: _busy ? null : _joinRoom, icon: const Icon(Icons.login), label: const Text('انضم للعبة')),
          ]))),
          const SizedBox(height: 12),
          _gameCard(context, Icons.emoji_events_outlined, 'Challenges',
            'تحديات يومية ونتائج اجتماعية ستتوسع مع ألعاب AUREN القادمة.',
            OutlinedButton.icon(onPressed: () => _snack('التحديات ستتوسع مع ألعاب AUREN القادمة.'), icon: const Icon(Icons.flag_outlined), label: const Text('استكشف'))),
          const SizedBox(height: 12),
          _friendChallengeCard(),
          const SizedBox(height: 12),
          _gameCard(context, Icons.groups_outlined, 'Social Play',
            'غرف لعب، دعوات ومنافسات مرتبطة بتجربة AUREN.',
            OutlinedButton.icon(onPressed: () => _snack('Social Play متصل حالياً بغرف الألعاب.'), icon: const Icon(Icons.people_outline), label: const Text('استكشف'))),
        ] else ...[
          if (_inviteCode != null) Card(child: ListTile(leading: const Icon(Icons.share_outlined), title: const Text('رمز الغرفة'),
            subtitle: Text(_inviteCode!, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
            trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: _inviteCode!)); _snack('تم نسخ رمز اللعبة.'); }))),
          const SizedBox(height: 10),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _service.watchRoom(_roomId!), builder: (context, snap) {
              if (snap.hasError) return const Text('تعذر تحميل اللعبة.');
              final data = snap.data?.data();
              if (data == null) return const Text('الغرفة غير متاحة.');
              return Column(children: [
                _buildBoard(context, data, uid),
                const SizedBox(height: 10),
                if (data['winner'] != null || data['draw'] == true)
                  FilledButton.icon(onPressed: () => _claimDailyChallenge(data), icon: const Icon(Icons.workspace_premium), label: const Text('استلام 25 XP')),
                const SizedBox(height: 18),
                _buildChat(),
              ]);
            }),
        ],
      ]),
    );
  }

  Widget _statsCard() => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Gaming Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 8), Text('$_xp XP  •  $_games مباريات  •  $_wins انتصارات')])), CircleAvatar(radius: 25, child: Text('${_xp ~/ 100 + 1}'))])));

  Widget _seasonCard() {
    final season = _service.currentSeasonId();
    final level = _seasonXp ~/ 250 + 1;
    final progress = (_seasonXp % 250) / 250;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.workspace_premium_outlined),
            const SizedBox(width: 10),
            Expanded(child: Text('الموسم ' + season, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
            Text('المستوى ' + level.toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          Text(_seasonXp.toString() + ' Season XP • ' + (250 - (_seasonXp % 250)).toString() + ' XP للمستوى التالي'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ]),
      ),
    );
  }

  Widget _achievementsCard() {
    final achievements = <Map<String, dynamic>>[
      {'title': 'أول مباراة', 'done': _games >= 1, 'icon': Icons.sports_esports},
      {'title': 'أول انتصار', 'done': _wins >= 1, 'icon': Icons.emoji_events},
      {'title': '5 انتصارات', 'done': _wins >= 5, 'icon': Icons.military_tech},
      {'title': '10 مباريات', 'done': _games >= 10, 'icon': Icons.local_fire_department},
      {'title': '100 XP', 'done': _xp >= 100, 'icon': Icons.stars},
    ];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('الإنجازات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: achievements.map((a) => Chip(
        avatar: Icon(a['icon'] as IconData, size: 18),
        label: Text(a['title'] as String),
        side: BorderSide(color: a['done'] == true ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
      )).toList()),
    ])));
  }

  Widget _leaderboardCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('لوحة المتصدرين', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.watchLeaderboard(),
          builder: (context, snap) {
            if (snap.hasError) return const Text('تعذر تحميل لوحة المتصدرين.');
            final docs = snap.data?.docs ?? const [];
            if (docs.isEmpty) return const Text('ابدأ اللعب لتظهر في لوحة المتصدرين.');
            return Column(children: [
              for (var i = 0; i < docs.length; i++)
                ListTile(dense: true, leading: CircleAvatar(child: Text('${i + 1}')), title: Text(docs[i].data()['displayName']?.toString() ?? 'لاعب AUREN'), trailing: Text('${(docs[i].data()['xp'] as num?)?.toInt() ?? 0} XP')),
            ]);
          },
        ),
      ]),
    ),
  );
  Widget _incomingChallengesCard() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('دعوات الأصدقاء', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _service.watchFriendChallenges(uid), builder: (context, snap) {
        if (snap.hasError) return const Text('تعذر تحميل الدعوات.');
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) return const Text('لا توجد دعوات جديدة.');
        return Column(children: docs.map((doc) {
          final fromUid = doc.data()['fromUid']?.toString() ?? '';
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: _dbUser(fromUid), builder: (context, userSnap) {
            final name = userSnap.data?.data()?['displayName']?.toString().trim();
            final label = (name == null || name.isEmpty) ? 'لاعب AUREN' : name;
            return ListTile(leading: const CircleAvatar(child: Icon(Icons.sports_esports)), title: Text(label), subtitle: const Text('أرسل لك تحدي Tic-Tac-Toe'),
              trailing: Wrap(spacing: 4, children: [
                IconButton(tooltip: 'رفض', onPressed: _busy ? null : () => _respondChallenge(doc.id, false), icon: const Icon(Icons.close)),
                IconButton(tooltip: 'قبول', onPressed: _busy ? null : () => _respondChallenge(doc.id, true), icon: const Icon(Icons.check_circle)),
              ]));
          });
        }).toList());
      }),
    ])));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _dbUser(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

  Widget _outgoingChallengesCard() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('تحدياتك', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchOutgoingFriendChallenges(uid),
        builder: (context, snap) {
          if (snap.hasError) return const Text('تعذر تحميل حالة التحديات.');
          final docs = snap.data?.docs ?? const [];
          final accepted = docs.where((d) => d.data()['status']?.toString() == 'accepted' && (d.data()['roomId']?.toString() ?? '').isNotEmpty).toList();
          if (accepted.isEmpty) return const Text('لا توجد مباريات مقبولة بانتظارك.');
          return Column(children: accepted.map((doc) {
            final data = doc.data();
            final toUid = data['toUid']?.toString() ?? '';
            final roomId = data['roomId']?.toString() ?? '';
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _dbUser(toUid),
              builder: (context, userSnap) {
                final name = userSnap.data?.data()?['displayName']?.toString().trim();
                final label = (name == null || name.isEmpty) ? 'لاعب AUREN' : name;
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.sports_esports)),
                  title: Text('مباراة مع $label'),
                  subtitle: const Text('تم قبول التحدي — المباراة جاهزة'),
                  trailing: FilledButton(onPressed: () => setState(() { _roomId = roomId; _inviteCode = null; }), child: const Text('فتح')),
                );
              },
            );
          }).toList());
        },
      ),
    ])));
  }

  Future<void> _respondChallenge(String challengeId, bool accept) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final room = await _service.respondToFriendChallenge(uid, challengeId, accept);
      if (!mounted) return;
      if (room != null) { setState(() { _roomId = room.id; _inviteCode = room.inviteCode; }); _snack('🎮 تم قبول التحدي. المباراة جاهزة.'); }
      else { _snack('تم رفض التحدي.'); }
    } catch (_) { if (mounted) _snack('تعذر معالجة الدعوة.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Widget _friendChallengeCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('تحدي صديق', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        const Text('ابحث عن لاعب في AUREN وأرسل له تحدي Tic-Tac-Toe بضغطة واحدة.'),
        const SizedBox(height: 10),
        TextField(
          controller: _friendSearchController,
          onChanged: (value) => setState(() => _friendSearch = value.trim().toLowerCase()),
          decoration: const InputDecoration(
            labelText: 'ابحث بالاسم',
            hintText: 'مثلاً: Khalied',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        _playerSearchResults(),
      ]),
    ),
  );

  Widget _playerSearchResults() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final query = _friendSearch;
    if (uid == null || query.length < 2) {
      return const Text('اكتب حرفين على الأقل للبحث عن لاعب.');
    }
    final users = FirebaseFirestore.instance.collection('users')
        .orderBy('displayNameLower')
        .startAt([query])
        .endAt(['$query\\uf8ff'])
        .limit(12);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: users.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const Text('تعذر البحث عن اللاعبين.');
        final docs = (snap.data?.docs ?? const []).where((d) => d.id != uid).toList();
        if (docs.isEmpty) return const Text('لم نجد لاعباً بهذا الاسم.');
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final name = (data['displayName']?.toString().trim().isNotEmpty ?? false)
                ? data['displayName'].toString().trim() : 'لاعب AUREN';
            final photo = data['photoUrl']?.toString();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo == null || photo.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(name),
              subtitle: const Text('متاح لتحديات Gaming'),
              trailing: FilledButton(
                onPressed: _busy ? null : () => _challengeFriendUid(doc.id, name),
                child: const Text('تحدي'),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _challengeFriendUid(String friendUid, String name) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || friendUid.isEmpty || friendUid == uid) return;
    setState(() => _busy = true);
    try {
      await _service.createFriendChallenge(uid, friendUid);
      _friendUidController.text = friendUid;
      if (mounted) _snack('🎮 تم إرسال تحدي إلى $name.');
    } catch (_) {
      if (mounted) _snack('تعذر إرسال التحدي. ربما توجد دعوة قائمة بالفعل.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _challengeFriend() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final friendUid = _friendUidController.text.trim();
    if (uid == null || friendUid.isEmpty || friendUid == uid) {
      _snack('أدخل معرّف صديق صحيح.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.createFriendChallenge(uid, friendUid);
      _friendUidController.clear();
      if (mounted) _snack('🎮 تم إرسال تحدي المباراة لصديقك.');
    } catch (_) {
      if (mounted) _snack('تعذر إرسال التحدي.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _challengeCard(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(child: Icon(Icons.emoji_events_outlined)),
          const SizedBox(width: 12),
          const Expanded(child: Text('تحدي اليوم', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
          Text('$_xp XP', style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        const Text('العب مباراة Tic-Tac-Toe حتى النهاية واحصل على 25 XP.'),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: _xp >= 25 ? 1 : 0),
      ]),
    ),
  );

  Widget _hero(BuildContext context) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer])),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Play. Connect. Challenge.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      SizedBox(height: 8), Text('ألعاب خفيفة داخل AUREN مرتبطة بالأصدقاء والتحديات والهوية الاجتماعية.')
    ]));

  Widget _gameCard(BuildContext context, IconData icon, String title, String subtitle, Widget action) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      CircleAvatar(radius: 26, child: Icon(icon)), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 4),
        Text(subtitle), const SizedBox(height: 10), action,
      ]))
    ])));

  Widget _buildChat() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('دردشة اللاعبين', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.watchMessages(_roomId!),
              builder: (context, snap) {
                if (snap.hasError) return const Center(child: Text('تعذر تحميل الدردشة.'));
                final docs = snap.data?.docs ?? const [];
                if (docs.isEmpty) return const Center(child: Text('ابدأ الحديث مع خصمك 👋'));
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data();
                    final mine = data['senderUid']?.toString() == FirebaseAuth.instance.currentUser?.uid;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        child: Text(data['text']?.toString() ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _chatController,
              maxLength: 500,
              decoration: const InputDecoration(hintText: 'اكتب رسالة…', border: OutlineInputBorder(), counterText: ''),
              onSubmitted: (_) => _sendChat(),
            )),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _sendChat, icon: const Icon(Icons.send)),
          ]),
        ]),
      ),
    );
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_roomId == null || uid == null || text.isEmpty) return;
    try {
      await _service.sendMessage(_roomId!, uid, text);
      _chatController.clear();
    } catch (_) {
      if (mounted) _snack('تعذر إرسال الرسالة.');
    }
  }

  Widget _buildBoard(BuildContext context, Map<String, dynamic> data, String? uid) {
    final board = List<String>.from((data['board'] as List<dynamic>? ?? const []).map((e) => e.toString()));
    final players = List<String>.from((data['playerUids'] as List<dynamic>? ?? const []).map((e) => e.toString()));
    final marks = data['marks'] is Map ? Map<String, dynamic>.from(data['marks'] as Map) : <String, dynamic>{};
    final turnUid = data['turnUid']?.toString() ?? '';
    final winner = data['winner']?.toString();
    final draw = data['draw'] == true;
    final myMark = uid == null ? null : marks[uid]?.toString();
    final ready = players.length >= 2;
    final status = winner != null ? 'الفائز: ' + winner : draw ? 'تعادل 🤝' : !ready ? 'في انتظار لاعب آخر' : myMark == null ? 'أنت متفرج' : turnUid == uid ? 'دورك — ' + myMark : 'انتظر دور اللاعب الآخر';

    return Column(children: [
      Card(child: ListTile(leading: Icon(ready ? Icons.play_circle : Icons.hourglass_top), title: Text(ready ? 'اللعبة جاهزة' : 'في انتظار لاعب آخر'), subtitle: Text(status))),
      const SizedBox(height: 12),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemBuilder: (_, i) => AspectRatio(aspectRatio: 1, child: FilledButton(
          onPressed: ready && winner == null && !draw ? () => _play(i, data) : null,
          child: Text(board.length == 9 ? board[i] : '', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
        ))),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: () => setState(() { _roomId = null; _inviteCode = null; }), icon: const Icon(Icons.exit_to_app), label: const Text('الخروج من الغرفة')),
    ]);
  }
}

class AurenGamingRoom {
  final String id; final String inviteCode; final Map<String, dynamic> data;
  AurenGamingRoom(this.id, this.inviteCode, this.data);
}

class AurenGamingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createFriendChallenge(String fromUid, String toUid) async {
    if (fromUid == toUid || fromUid.isEmpty || toUid.isEmpty) {
      throw ArgumentError('Invalid challenge target.');
    }
    await _db.collection('gaming_friend_challenges').add({
      'fromUid': fromUid,
      'toUid': toUid,
      'gameId': 'tic_tac_toe',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AurenGamingRoom?> respondToFriendChallenge(String uid, String challengeId, bool accept) async {
    final challengeRef = _db.collection('gaming_friend_challenges').doc(challengeId);
    final snap = await challengeRef.get();
    if (!snap.exists) throw StateError('Challenge not found.');
    final data = snap.data() ?? {};
    if (data['toUid']?.toString() != uid || data['status']?.toString() != 'pending') throw StateError('Challenge is no longer available.');
    if (!accept) { await challengeRef.update({'status': 'declined'}); return null; }
    final fromUid = data['fromUid']?.toString() ?? '';
    if (fromUid.isEmpty || fromUid == uid) throw StateError('Invalid challenger.');
    final room = await createTicTacToeRoom(fromUid);
    final roomRef = _db.collection('gaming_rooms').doc(room.id);
    await _db.runTransaction((tx) async {
      final challengeSnap = await tx.get(challengeRef);
      if (!challengeSnap.exists || challengeSnap.data()?['status']?.toString() != 'pending') throw StateError('Challenge already handled.');
      tx.update(roomRef, {'playerUids': [fromUid, uid], 'marks.' + fromUid: 'X', 'marks.' + uid: 'O', 'status': 'ready', 'turnUid': fromUid, 'updatedAt': FieldValue.serverTimestamp()});
      tx.update(challengeRef, {'status': 'accepted', 'roomId': room.id, 'updatedAt': FieldValue.serverTimestamp()});
    });
    return AurenGamingRoom(room.id, room.inviteCode, {...room.data, 'playerUids': [fromUid, uid], 'status': 'ready', 'marks': {fromUid: 'X', uid: 'O'}});
  }
  Stream<QuerySnapshot<Map<String, dynamic>>> watchFriendChallenges(String uid) =>
      _db.collection('gaming_friend_challenges').where('toUid', isEqualTo: uid).where('status', isEqualTo: 'pending').limit(20).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> watchOutgoingFriendChallenges(String uid) =>
      _db.collection('gaming_friend_challenges').where('fromUid', isEqualTo: uid).limit(30).snapshots();

  Future<AurenGamingRoom> createTicTacToeRoom(String uid) async {
    final ref = _db.collection('gaming_rooms').doc();
    final invite = _makeCode();
    final data = {'gameId':'tic_tac_toe','hostUid':uid,'playerUids':[uid],'marks':{uid:'X'},'board':List<String>.filled(9,''),'turnUid':uid,'winner':null,'draw':false,'status':'waiting','inviteCode':invite,'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()};
    await ref.set(data);
    await _db.collection('gaming_invites').doc(invite).set({'roomId':ref.id,'hostUid':uid,'inviteCode':invite,'createdAt':FieldValue.serverTimestamp()});
    return AurenGamingRoom(ref.id, invite, data);
  }

  Future<AurenGamingRoom> joinTicTacToeRoom(String uid, String code) async {
    final inviteSnap = await _db.collection('gaming_invites').doc(code).get();
    if (!inviteSnap.exists) throw StateError('رمز اللعبة غير صحيح.');
    final roomId = inviteSnap.data()?['roomId']?.toString();
    if (roomId == null || roomId.isEmpty) throw StateError('الغرفة غير موجودة.');
    final ref = _db.collection('gaming_rooms').doc(roomId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('الغرفة غير موجودة.');
      final data = snap.data() ?? {};
      final players = List<String>.from((data['playerUids'] as List<dynamic>? ?? const []).map((e) => e.toString()));
      if (players.contains(uid)) return;
      if (players.length >= 2) throw StateError('الغرفة ممتلئة.');
      players.add(uid);
      tx.update(ref, {'playerUids':players,'marks.' + uid:'O','status':'ready','updatedAt':FieldValue.serverTimestamp()});
    });
    final snap = await ref.get();
    return AurenGamingRoom(roomId, code, snap.data() ?? {});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) => _db.collection('gaming_rooms').doc(roomId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String roomId) =>
      _db.collection('gaming_rooms').doc(roomId).collection('messages').orderBy('createdAt', descending: true).limit(50).snapshots();

  Future<void> sendMessage(String roomId, String uid, String text) =>
      _db.collection('gaming_rooms').doc(roomId).collection('messages').add({
        'senderUid': uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<AurenGamingStats> getStats(String uid) async {
    final snap = await _db.collection('users').doc(uid).collection('gaming_profile').doc('stats').get();
    final data = snap.data() ?? {};
    return AurenGamingStats(xp: (data['xp'] as num?)?.toInt() ?? 0, games: (data['games'] as num?)?.toInt() ?? 0, wins: (data['wins'] as num?)?.toInt() ?? 0, seasonXp: (data['seasonXp'] as num?)?.toInt() ?? 0);
  }

  Future<void> recordResult(String uid, String roomId, bool win, bool draw) async {
    final ref = _db.collection('users').doc(uid).collection('gaming_results').doc(roomId);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({'roomId': roomId, 'gameId': 'tic_tac_toe', 'result': draw ? 'draw' : win ? 'win' : 'loss', 'xp': win ? 50 : 15, 'createdAt': FieldValue.serverTimestamp()});
    await incrementStats(uid, win: win);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLeaderboard() => _db.collectionGroup('gaming_profile').orderBy('xp', descending: true).limit(50).snapshots();

  String currentSeasonId() {
    final now = DateTime.now().toUtc();
    return now.year.toString() + '-S' + (((now.month - 1) ~/ 3) + 1).toString();
  }

  Future<void> incrementStats(String uid, {required bool win}) async {
    final user = FirebaseAuth.instance.currentUser;
    final gain = win ? 50 : 15;
    await _db.collection('users').doc(uid).collection('gaming_profile').doc('stats').set({
      'xp': FieldValue.increment(gain), 'seasonXp': FieldValue.increment(gain), 'seasonId': currentSeasonId(), 'games': FieldValue.increment(1), 'wins': FieldValue.increment(win ? 1 : 0), 'displayName': user?.displayName ?? 'لاعب AUREN', 'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> claimDailyChallenge(String uid) async {
    final now = DateTime.now().toUtc();
    final key = now.year.toString() + '-' + now.month.toString().padLeft(2, '0') + '-' + now.day.toString().padLeft(2, '0');
    final ref = _db.collection('users').doc(uid).collection('gaming_challenges').doc(key);
    final snap = await ref.get();
    if (snap.exists) return false;
    await ref.set({
      'challengeId': 'daily_tic_tac_toe',
      'xp': 25,
      'completedAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('users').doc(uid).collection('gaming_profile').doc('stats').set({
      'xp': FieldValue.increment(25), 'seasonXp': FieldValue.increment(25), 'seasonId': currentSeasonId(), 'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  Future<void> playMove({required String roomId, required List<String> board, required String? winner, required bool draw, required String nextUid}) =>
    _db.collection('gaming_rooms').doc(roomId).update({'board':board,'winner':winner,'draw':draw,'turnUid':nextUid,'updatedAt':FieldValue.serverTimestamp()});

  String _makeCode() {
    const chars='ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; var n=DateTime.now().microsecondsSinceEpoch; final out=StringBuffer();
    for (var i=0;i<6;i++){out.write(chars[n%chars.length]);n=(n~/chars.length)+i*17;} return out.toString();
  }
}

class AurenGamingStats { final int xp; final int games; final int wins; final int seasonXp; const AurenGamingStats({required this.xp, required this.games, required this.wins, required this.seasonXp}); }
