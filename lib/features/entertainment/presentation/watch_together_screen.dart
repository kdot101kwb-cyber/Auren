import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

class AurenWatchTogetherService {
  final FirebaseFirestore _db;
  AurenWatchTogetherService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('watch_together_rooms');
  CollectionReference<Map<String, dynamic>> get _invites => _db.collection('watch_together_invites');
  String _code() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }
  Future<String> createRoom({required String title, String? mediaId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('سجّل الدخول أولاً.');
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _code();
      final ref = _rooms.doc();
      final inviteRef = _invites.doc(code);
      try {
        await _db.runTransaction((tx) async {
          final existing = await tx.get(inviteRef);
          if (existing.exists) throw StateError('INVITE_CODE_COLLISION');
          final roomTitle = title.trim().isEmpty ? 'Watch Together' : title.trim();
          tx.set(ref, {
            'hostUid': uid,
            'memberIds': [uid],
            'inviteCode': code,
            'title': roomTitle.length > 160 ? roomTitle.substring(0, 160) : roomTitle,
            'mediaId': mediaId,
            'channelId': mediaId?.trim().isNotEmpty == true ? mediaId!.trim() : 'media',
            'channelName': roomTitle.length > 160 ? roomTitle.substring(0, 160) : roomTitle,
            'status': 'waiting',
            'positionSeconds': 0,
            'isPlaying': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          tx.set(inviteRef, {'roomId': ref.id, 'hostUid': uid, 'inviteCode': code, 'createdAt': FieldValue.serverTimestamp()});
        });
        return ref.id;
      } on StateError catch (e) {
        if (e.message != 'INVITE_CODE_COLLISION' || attempt == 4) rethrow;
      }
    }
    throw StateError('تعذر إنشاء رمز دعوة آمن.');
  }

  Future<String> joinRoom(String code) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('سجّل الدخول أولاً.');
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 6) throw StateError('رمز الغرفة يجب أن يكون 6 أحرف.');
    final invite = await _invites.doc(normalized).get();
    if (!invite.exists) throw StateError('رمز الغرفة غير صحيح.');
    final roomId = (invite.data()?['roomId'] ?? '').toString();
    if (roomId.isEmpty) throw StateError('الغرفة غير متاحة.');
    final ref = _rooms.doc(roomId);
    await _db.runTransaction((tx) async {
      final current = await tx.get(ref);
      if (!current.exists) throw StateError('الغرفة غير متاحة.');
      final data = current.data() ?? <String, dynamic>{};
      final members = List<String>.from(data['memberIds'] ?? const <String>[]);
      if (members.contains(uid)) return;
      if (members.length >= 8) throw StateError('الغرفة ممتلئة.');
      members.add(uid);
      tx.update(ref, {'memberIds': members, 'status': 'ready', 'updatedAt': FieldValue.serverTimestamp()});
    });
    return roomId;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) => _rooms.doc(roomId).snapshots();
  Future<void> updatePlayback({required String roomId, required double positionSeconds, required bool isPlaying}) => _rooms.doc(roomId).update({'positionSeconds': positionSeconds.clamp(0, 86400), 'isPlaying': isPlaying, 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> leaveRoom(String roomId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('سجّل الدخول أولاً.');
    final ref = _rooms.doc(roomId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? <String, dynamic>{};
      if (data['hostUid'] == uid) throw StateError('المضيف يجب أن ينهي الغرفة.');
      final members = List<String>.from(data['memberIds'] ?? const <String>[]);
      if (!members.contains(uid)) return;
      members.remove(uid);
      tx.update(ref, {'memberIds': members, 'status': members.length > 1 ? 'ready' : 'waiting', 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  Future<void> deleteRoom(String roomId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('سجّل الدخول أولاً.');
    final roomRef = _rooms.doc(roomId);
    await _db.runTransaction((tx) async {
      final room = await tx.get(roomRef);
      if (!room.exists) return;
      final data = room.data() ?? <String, dynamic>{};
      if (data['hostUid'] != uid) throw StateError('فقط المضيف يستطيع إنهاء الغرفة.');
      final code = (data['inviteCode'] ?? '').toString().toUpperCase();
      tx.delete(roomRef);
      if (code.isNotEmpty) tx.delete(_invites.doc(code));
    });
  }
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String roomId) => _rooms.doc(roomId).collection('messages').orderBy('createdAt', descending: true).limit(50).snapshots();
  Future<void> sendMessage(String roomId, String text) async { final uid = FirebaseAuth.instance.currentUser?.uid; final value = text.trim(); if (uid == null || value.isEmpty) return; await _rooms.doc(roomId).collection('messages').add({'senderUid': uid, 'text': value, 'createdAt': FieldValue.serverTimestamp()}); }
}

class AurenWatchTogetherAnalytics {
  static String statusLabel(String status) {
    switch (status) {
      case 'ready':
        return 'جاهزة للمشاهدة';
      case 'waiting':
        return 'بانتظار الأصدقاء';
      default:
        return status;
    }
  }

  static String membersLabel(int count) =>
      count == 1 ? 'أنت وحدك' : '$count مشاركين';
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
  String? _syncError;
  VideoPlayerController? _controller;
  bool _syncingRemote = false;
  DateTime? _lastRemoteSync;
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
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty || _sharing) return;
    setState(() => _sharing = true);
    try {
      final title = widget.title?.trim().isNotEmpty == true ? widget.title!.trim() : 'Watch Together';
      await SharePlus.instance.share(
        ShareParams(
          text: 'انضم لمشاهدة «$title» معي في AUREN. رمز الغرفة: $normalized',
          subject: 'دعوة Watch Together في AUREN',
        ),
      );
    } catch (e) {
      if (mounted) _show(e.toString());
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
  Future<void> _syncFromRoom(Map<String, dynamic> data) async { if (_controller == null || !_controller!.value.isInitialized || _syncingRemote) return; final remotePosition = ((data['positionSeconds'] ?? 0) as num).toDouble(); final remotePlaying = data['isPlaying'] == true; final local = _controller!.value.position.inMilliseconds / 1000.0; if ((local - remotePosition).abs() > 1.5) { _syncingRemote = true; try { await _controller!.seekTo(Duration(milliseconds: (remotePosition * 1000).round())); } finally { _syncingRemote = false; } } if (remotePlaying && !_controller!.value.isPlaying) await _controller!.play(); if (!remotePlaying && _controller!.value.isPlaying) await _controller!.pause(); if (mounted) setState(() => _lastRemoteSync = DateTime.now()); }
  Future<void> _retrySync() async {
    if (_roomId == null || _controller == null || !_controller!.value.isInitialized) return;
    if (_syncingRemote) return;
    setState(() => _syncError = null);
    try {
      final position = _controller!.value.position.inMilliseconds / 1000.0;
      await _service.updatePlayback(roomId: _roomId!, positionSeconds: position, isPlaying: _controller!.value.isPlaying);
    } catch (e) {
      if (mounted) setState(() => _syncError = e.toString());
    }
  }

  Future<void> _togglePlayback(String roomId, Map<String, dynamic> data) async {
    if (_syncingRemote) return;
    final controller = _controller;
    final currentPosition = controller?.value.isInitialized == true
        ? controller!.value.position.inMilliseconds / 1000.0
        : ((data['positionSeconds'] ?? 0) as num).toDouble();
    final nextPlaying = !(data['isPlaying'] == true);
    try {
      await _service.updatePlayback(roomId: roomId, positionSeconds: currentPosition, isPlaying: nextPlaying);
      if (controller?.value.isInitialized == true) {
        if (nextPlaying) await controller!.play();
        else await controller!.pause();
      }
      if (mounted) setState(() => _syncError = null);
    } catch (e) {
      if (mounted) setState(() => _syncError = e.toString());
    }
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
          Text('الحالة: ' + AurenWatchTogetherAnalytics.statusLabel((data['status'] ?? 'waiting').toString())),
          Text(AurenWatchTogetherAnalytics.membersLabel(members.length) + ' • ' +
              'المشاهدة: ' + ((data['isPlaying'] == true) ? 'تشغيل' : 'متوقفة') +
              ' • ' + (data['positionSeconds'] ?? 0).toString() + ' ثانية'),
          if (_syncError != null) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: Colors.redAccent.withOpacity(.12)), child: Row(children: [const Expanded(child: Text('تعذر تحديث حالة المشاهدة.')) , TextButton(onPressed: _retrySync, child: const Text('إعادة المحاولة'))]))],
          const SizedBox(height: 14),
          if (members.length < 8)
            OutlinedButton.icon(
              onPressed: () => _shareInvite((data['inviteCode'] ?? '').toString()),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('دعوة صديق'),
            ),
          if (FirebaseAuth.instance.currentUser?.uid != data['hostUid'])
            OutlinedButton.icon(onPressed: _busy ? null : () async { setState(() => _busy = true); try { await _service.leaveRoom(roomId); if (mounted) setState(() => _roomId = null); } catch (e) { _show(e.toString()); } finally { if (mounted) setState(() => _busy = false); } }, icon: const Icon(Icons.logout_rounded), label: const Text('مغادرة الغرفة')),
          if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty) _buildSyncedPlayer(roomId, data),
          if (_lastRemoteSync != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('آخر مزامنة: ${_lastRemoteSync!.hour.toString().padLeft(2,'0')}:${_lastRemoteSync!.minute.toString().padLeft(2,'0')}:${_lastRemoteSync!.second.toString().padLeft(2,'0')}'));
          if (widget.mediaUrl == null || widget.mediaUrl!.isEmpty)
            FilledButton.icon(
              onPressed: data['hostUid'] == FirebaseAuth.instance.currentUser?.uid
                  ? () => _service.updatePlayback(
                      roomId: roomId,
                      positionSeconds: ((data['positionSeconds'] ?? 0) as num).toDouble(),
                      isPlaying: !(data['isPlaying'] == true),
                    )
                  : null,
              icon: Icon(data['isPlaying'] == true ? Icons.pause : Icons.play_arrow),
              label: Text(data['hostUid'] == FirebaseAuth.instance.currentUser?.uid
                  ? (data['isPlaying'] == true ? 'إيقاف' : 'تشغيل')
                  : 'المضيف يتحكم'),
            ),
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
    final isHost = data['hostUid'] == FirebaseAuth.instance.currentUser?.uid;
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
        onPressed: !isHost || _syncingRemote ? null : () async {
          final next = !controller.value.isPlaying;
          final position = controller.value.position.inMilliseconds / 1000.0;
          try {
            await _service.updatePlayback(roomId: roomId, positionSeconds: position, isPlaying: next);
            if (mounted) setState(() => _syncError = null);
          } catch (e) {
            if (mounted) setState(() => _syncError = e.toString());
            return;
          }
          if (next) { await controller.play(); } else { await controller.pause(); }
          if (mounted) setState(() {});
        },
        icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
        label: Text(isHost
            ? (controller.value.isPlaying ? 'إيقاف للجميع' : 'تشغيل للجميع')
            : 'المضيف يتحكم'),
      ),
    ]);
  }

}