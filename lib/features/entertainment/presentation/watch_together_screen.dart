import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
}

class AurenWatchTogetherScreen extends StatefulWidget {
  const AurenWatchTogetherScreen({super.key});
  @override State<AurenWatchTogetherScreen> createState() => _AurenWatchTogetherScreenState();
}
class _AurenWatchTogetherScreenState extends State<AurenWatchTogetherScreen> {
  final _service = AurenWatchTogetherService();
  final _title = TextEditingController();
  final _code = TextEditingController();
  String? _roomId;
  bool _busy = false;
  @override void dispose() { _title.dispose(); _code.dispose(); super.dispose(); }
  Future<void> _create() async {
    setState(() => _busy = true);
    try { _roomId = await _service.createRoom(title: _title.text); if (mounted) setState(() {}); }
    catch (e) { _show(e.toString()); } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _join() async {
    setState(() => _busy = true);
    try { _roomId = await _service.joinRoom(_code.text); if (mounted) setState(() {}); }
    catch (e) { _show(e.toString()); } finally { if (mounted) setState(() => _busy = false); }
  }
  void _show(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value.replaceFirst('Bad state: ', ''))));
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
          SelectableText('رمز الدعوة: ' + (data['inviteCode'] ?? '').toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8), Text('الأعضاء: ' + members.length.toString()),
          Text('الحالة: ' + (data['status'] ?? 'waiting').toString()),
          Text('المشاهدة: ' + ((data['isPlaying'] == true) ? 'تشغيل' : 'متوقفة') + ' • ' + (data['positionSeconds'] ?? 0).toString() + ' ثانية'),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: () => _service.updatePlayback(roomId: roomId, positionSeconds: ((data['positionSeconds'] ?? 0) as num).toDouble(), isPlaying: !(data['isPlaying'] == true)), icon: Icon(data['isPlaying'] == true ? Icons.pause : Icons.play_arrow), label: Text(data['isPlaying'] == true ? 'إيقاف' : 'تشغيل')),
        ])));
      }),
    ]));
  }
}