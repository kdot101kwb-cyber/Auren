import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class AurenWatchTogetherService {
  final FirebaseFirestore _db;
  AurenWatchTogetherService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('watch_together_rooms');
  String _code() => DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(4);
  Future<String> createRoom({required String title, String? mediaId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('سجّل الدخول أولاً.');
    final ref = _rooms.doc();
    await ref.set({'hostUid': uid, 'memberIds': [uid], 'inviteCode': _code(), 'title': title.trim().isEmpty ? 'Watch Together' : title.trim(), 'mediaId': mediaId, 'status': 'waiting', 'positionSeconds': 0, 'isPlaying': false, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
    return ref.id;
  }
  Future<String> joinRoom(String code) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('سجّل الدخول أولاً.');
    final snap = await _rooms.where('inviteCode', isEqualTo: code.trim().toUpperCase()).limit(1).get();
    if (snap.docs.isEmpty) throw StateError('رمز الغرفة غير صحيح.');
    final ref = snap.docs.first.reference;
    await _db.runTransaction((tx) async {
      final current = await tx.get(ref);
      final data = current.data() ?? <String, dynamic>{};
      final members = List<String>.from(data['memberIds'] ?? const <String>[]);
      if (!members.contains(uid)) members.add(uid);
      tx.update(ref, {'memberIds': members, 'status': 'ready', 'updatedAt': FieldValue.serverTimestamp()});
    });
    return ref.id;
  }
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) => _rooms.doc(roomId).snapshots();
  Future<void> updatePlayback({required String roomId, required double positionSeconds, required bool isPlaying}) => _rooms.doc(roomId).update({'positionSeconds': positionSeconds.clamp(0, 86400), 'isPlaying': isPlaying, 'updatedAt': FieldValue.serverTimestamp()});
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String roomId) => _rooms.doc(roomId).collection('messages').orderBy('createdAt', descending: true).limit(50).snapshots();
  Future<void> sendMessage(String roomId, String text) async { final uid = FirebaseAuth.instance.currentUser?.uid; final value = text.trim(); if (uid == null || value.isEmpty) return; await _rooms.doc(roomId).collection('messages').add({'senderUid': uid, 'text': value, 'createdAt': FieldValue.serverTimestamp()}); }
}

class AurenWatchTogetherScreen extends StatefulWidget {
  final String? title;
  final String? mediaUrl;
  final String? mediaId;
  const AurenWatchTogetherScreen({super.key, this.title, this.mediaUrl, this.mediaId});
  @override State<AurenWatchTogetherScreen> createState() => _AurenWatchTogetherScreenState();
}
class _AurenWatchTogetherScreenState extends State<AurenWatchTogetherScreen> {
  final _service = AurenWatchTogetherService();
  final _title = TextEditingController();
  final _code = TextEditingController();
  String? _roomId;
  bool _busy = false;
  bool _sharing = false;
  VideoPlayerController? _controller;
  bool _syncingRemote = false;
  final _chat = TextEditingController();
  @override void dispose() { _title.dispose(); _code.dispose(); _chat.dispose(); _controller?.dispose(); super.dispose(); }
  Future<void> _create() async {
    setState(() => _busy = true);
    try { _roomId = await _service.createRoom(title: widget.title ?? _title.text, mediaId: widget.mediaId); if (mounted) setState(() {}); }
    catch (e) { _show(e.toString()); } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _join() async {
    setState(() => _busy = true);
    try { _roomId = await _service.joinRoom(_code.text); if (mounted) setState(() {}); }
    catch (e) { _show(e.toString()); } finally { if (mounted) setState(() => _busy = false); }
  }
  void _show(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value.replaceFirst('Bad state: ', ''))));
  Future<void> _shareInvite(String code) async {
    if (code.isEmpty || _sharing) return;
    setState(() => _sharing = true);
    try {
      await Clipboard.setData(ClipboardData(text: 'انضم إلى غرفة Watch Together في AUREN 🎬\nرمز الدعوة: $code'));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ دعوة الغرفة للمشاركة')));
    } finally { if (mounted) setState(() => _sharing = false); }
  }
  @override Widget build(BuildContext context) {
    final roomId = _roomId;
    return Scaffold(appBar: AppBar(title: const Text('Watch Together')), body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('شاهدوا معاً', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('أنشئ غرفة وشارك رمزها مع أصدقائك. حالة التشغيل وموقع المشاهدة تُحفظ في الغرفة للمزامنة لاحقاً.'),
      const SizedBox(height: 22),
      if (roomId == null) ...[
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'اسم الغرفة', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _busy ? null : _create, icon: const Icon(Icons.add), label: const Text('إنشاء غرفة')),
        const SizedBox(height: 24), const Divider(), const SizedBox(height: 16),
        TextField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'رمز الدعوة', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: _busy ? null : _join, icon: const Icon(Icons.group_add_outlined), label: const Text('الانضمام لغرفة')),
      ] else StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: _service.watchRoom(roomId), builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final members = List<String>.from(data['memberIds'] ?? const <String>[]);
        return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((data['title'] ?? 'Watch Together').toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: SelectableText('رمز الدعوة: ' + (data['inviteCode'] ?? '').toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))), IconButton(onPressed: () async { final code = (data['inviteCode'] ?? '').toString(); if (code.isEmpty) return; await Clipboard.setData(ClipboardData(text: code)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رمز الدعوة'))); }, icon: const Icon(Icons.copy)), IconButton(onPressed: _sharing ? null : () => _shareInvite((data['inviteCode'] ?? '').toString()), icon: const Icon(Icons.share))]),
          const SizedBox(height: 8), Text('الأعضاء: ' + members.length.toString()),
          Text('الحالة: ' + (data['status'] ?? 'waiting').toString()),
          Text('المشاهدة: ' + ((data['isPlaying'] == true) ? 'تشغيل' : 'متوقفة') + ' • ' + (data['positionSeconds'] ?? 0).toString() + ' ثانية'),
          const SizedBox(height: 14),
          if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty) _buildSyncedPlayer(roomId, data),
          if (widget.mediaUrl == null || widget.mediaUrl!.isEmpty)
            FilledButton.icon(onPressed: () => _service.updatePlayback(roomId: roomId, positionSeconds: ((data['positionSeconds'] ?? 0) as num).toDouble(), isPlaying: !(data['isPlaying'] == true)), icon: Icon(data['isPlaying'] == true ? Icons.pause : Icons.play_arrow), label: Text(data['isPlaying'] == true ? 'إيقاف' : 'تشغيل')),
          const SizedBox(height: 18),
          const Text('دردشة الغرفة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.watchMessages(roomId),
            builder: (context, chatSnapshot) {
              final messages = chatSnapshot.data?.docs ?? const [];
              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (_, index) {
                  final message = messages[index].data();
                  final mine = message['senderUid'] == FirebaseAuth.instance.currentUser?.uid;
                  return Align(alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart, child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                    child: Text((message['text'] ?? '').toString()),
                  ));
                },
              );
            },
          )),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _chat, maxLength: 1000, decoration: const InputDecoration(hintText: 'اكتب رسالة...', border: OutlineInputBorder(), counterText: ''))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: () async { final text = _chat.text; _chat.clear(); await _service.sendMessage(roomId, text); }, icon: const Icon(Icons.send)),
          ]),
        ])));
      }),
    ]));
  }
  Widget _buildSyncedPlayer(String roomId, Map<String, dynamic> data) {
    final remotePosition = ((data['positionSeconds'] ?? 0) as num).toDouble();
    final remotePlaying = data['isPlaying'] == true;
    if (_controller == null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl!));
      _controller!.initialize().then((_) async {
        if (!mounted) return;
        await _controller!.seekTo(Duration(milliseconds: (remotePosition * 1000).round()));
        if (remotePlaying) await _controller!.play();
        if (mounted) setState(() {});
      });
    } else if (_controller!.value.isInitialized && !_syncingRemote) {
      final local = _controller!.value.position.inMilliseconds / 1000.0;
      if ((local - remotePosition).abs() > 1.5) {
        _syncingRemote = true;
        _controller!.seekTo(Duration(milliseconds: (remotePosition * 1000).round())).whenComplete(() => _syncingRemote = false);
      }
      if (remotePlaying && !_controller!.value.isPlaying) _controller!.play();
      if (!remotePlaying && _controller!.value.isPlaying) _controller!.pause();
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator()));
    }
    return Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller))),
      VideoProgressIndicator(controller, allowScrubbing: true),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: _syncingRemote ? null : () async {
          final next = !controller.value.isPlaying;
          final position = controller.value.position.inMilliseconds / 1000.0;
          await _service.updatePlayback(roomId: roomId, positionSeconds: position, isPlaying: next);
          if (next) { await controller.play(); } else { await controller.pause(); }
          if (mounted) setState(() {});
        },
        icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
        label: Text(controller.value.isPlaying ? 'إيقاف للجميع' : 'تشغيل للجميع'),
      ),
    ]);
  }

}