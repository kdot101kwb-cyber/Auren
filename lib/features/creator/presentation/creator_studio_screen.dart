import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../../services/creator/creator_studio_repository.dart';
import 'creator_growth_screen.dart';
import 'creator_earnings_screen.dart';

class AurenCreatorStudioScreen extends StatefulWidget {
  const AurenCreatorStudioScreen({super.key});
  @override State<AurenCreatorStudioScreen> createState() => _AurenCreatorStudioScreenState();
}

class _AurenCreatorStudioScreenState extends State<AurenCreatorStudioScreen> {
  final _repo = AurenCreatorStudioRepository();
  final _text = TextEditingController();
  final _media = TextEditingController();
  final _tags = TextEditingController();
  String _mediaType = 'none';
  String _contentType = 'creator';
  String _category = 'حسب مزاج المستخدم';

  static const _shortCategories = <String>[
    'حسب مزاج المستخدم', 'كرتون', 'كوميديا', 'فلوقات', 'موسيقى',
    'ألعاب', 'تعليمي', 'رياضة', 'منوعات',
  ];
  bool _publishing = false;
  XFile? _pickedVideo;
  double? _uploadProgress;
  static const int _maxShortBytes = 25 * 1024 * 1024;
  Future<AurenCreatorStats>? _stats;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override void initState() {
    super.initState();
    final uid = _uid;
    if (uid != null) _stats = _repo.loadStats(uid);
  }

  @override void dispose() {
    _text.dispose();
    _media.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickShortVideo() async {
    try {
      final picked = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (picked == null || !mounted) return;
      final size = await File(picked.path).length();
      if (size > _maxShortBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حجم الفيديو يجب ألا يتجاوز 25 ميغابايت حالياً.')),
        );
        return;
      }
      final mimeType = picked.mimeType ?? '';
      if (mimeType.isNotEmpty && !mimeType.startsWith('video/')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الملف المحدد ليس فيديو صالحاً.')),
        );
        return;
      }
      setState(() {
        _pickedVideo = picked;
        _mediaType = 'video';
        _media.clear();
        _uploadProgress = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار الفيديو: $e')),
        );
      }
    }
  }

  Future<String> _uploadShortVideo(String uid) async {
    final picked = _pickedVideo;
    if (picked == null) return _media.text.trim();
    final file = File(picked.path);
    final size = await file.length();
    if (size <= 0 || size > _maxShortBytes) {
      throw ArgumentError('حجم الفيديو يجب أن يكون بين 1 بايت و25 ميغابايت.');
    }

    final extension = picked.name.contains('.')
        ? picked.name.split('.').last.toLowerCase()
        : 'mp4';
    final fallbackMime = switch (extension) {
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      '3gp' => 'video/3gpp',
      _ => 'video/mp4',
    };
    final suppliedMime = picked.mimeType ?? '';
    final contentType = suppliedMime.startsWith('video/')
        ? suppliedMime
        : fallbackMime;
    final objectName = 'short_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final ref = FirebaseStorage.instance
        .ref()
        .child('users/$uid/media/shorts/$objectName');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );
    await for (final snapshot in task.snapshotEvents) {
      if (mounted) {
        setState(() {
          _uploadProgress = snapshot.totalBytes == 0
              ? 0
              : snapshot.bytesTransferred / snapshot.totalBytes;
        });
      }
    }
    return ref.getDownloadURL();
  }

  Future<void> _publish() async {
    final uid = _uid;
    if (uid == null || _publishing) return;
    setState(() => _publishing = true);
    try {
      var mediaUrl = _media.text.trim();
      if (_contentType == 'short' && _pickedVideo != null) {
        mediaUrl = await _uploadShortVideo(uid);
        _media.text = mediaUrl;
      }
      await _repo.publish(
        uid: uid,
        text: _text.text,
        mediaUrl: mediaUrl,
        mediaType: _mediaType,
        contentType: _contentType,
        category: _category,
        tags: _tags.text.split(RegExp(r'[,،\s]+')),
      );
      _text.clear();
      _media.clear();
      _tags.clear();
      _pickedVideo = null;
      _uploadProgress = null;
      _refreshStats();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_contentType == 'short'
            ? 'تم نشر الشورت في Creator Studio وموجز AUREN Shorts.'
            : 'تم نشر المحتوى في Creator Studio.'),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر النشر: $e')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _refreshStats() {
    final uid = _uid;
    if (uid != null) setState(() => _stats = _repo.loadStats(uid));
  }

  @override Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required')));
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Studio'), actions: [IconButton(onPressed: _refreshStats, icon: const Icon(Icons.refresh))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Text('Creator Studio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('أنشئ وانشر وتابع أداء محتواك من مكان واحد. صفحة Creator تعتمد على AI Profile Mode.'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Creator Earnings'),
              subtitle: const Text('تابع الدعم المسجل وحالة التسوية من مكان واحد.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AurenCreatorEarningsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights_rounded),
              title: const Text('Creator Growth Engine'),
              subtitle: const Text('خطط للمحتوى، راقب الأداء، وجدول أفكارك القادمة.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AurenCreatorGrowthScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<AurenCreatorStats>(
            future: _stats,
            builder: (context, snap) {
              final data = snap.data;
              if (snap.connectionState == ConnectionState.waiting && data == null) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())));
              return Row(children: [
                _stat('المحتوى', '${data?.posts ?? 0}', Icons.grid_view_rounded),
                _stat('الإعجابات', '${data?.likes ?? 0}', Icons.favorite_border),
                _stat('Media', '${data?.mediaPosts ?? 0}', Icons.perm_media_outlined),
              ]);
            },
          ),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Publish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(controller: _text, minLines: 4, maxLines: 8, maxLength: _contentType == 'short' ? 3000 : 4000, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'اكتب فكرة، قصة، إعلان، فيديو أو محتوى لجمهورك...')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _contentType,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'مكان النشر'),
              items: const [
                DropdownMenuItem(value: 'creator', child: Text('منشور عادي')),
                DropdownMenuItem(value: 'short', child: Text('AUREN Shorts')),
              ],
              onChanged: (v) => setState(() {
                _contentType = v ?? 'creator';
                if (_contentType == 'short') _mediaType = 'video';
              }),
            ),
            const SizedBox(height: 8),
            if (_contentType == 'short') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _publishing ? null : _pickShortVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: Text(_pickedVideo == null
                      ? 'اختيار فيديو من الجهاز'
                      : 'تغيير الفيديو المحدد'),
                ),
              ),
              if (_pickedVideo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${_pickedVideo!.name} • ${(File(_pickedVideo!.path).lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'فيديو حتى 3 دقائق و25 ميغابايت. يمكنك أيضاً لصق رابط فيديو جاهز أدناه.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (_uploadProgress != null) ...[
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 4),
                Text('رفع الفيديو: ${(_uploadProgress! * 100).round()}%'),
                const SizedBox(height: 8),
              ],
            ],
            TextField(
              controller: _media,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _contentType == 'short' ? 'رابط الفيديو (مطلوب للشورت)' : 'Media URL (اختياري)',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _mediaType,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'نوع الوسائط'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('بدون')),
                DropdownMenuItem(value: 'image', child: Text('صورة')),
                DropdownMenuItem(value: 'video', child: Text('فيديو')),
                DropdownMenuItem(value: 'audio', child: Text('صوت')),
              ],
              onChanged: (v) => setState(() => _mediaType = v ?? 'none'),
            ),
            if (_contentType == 'short') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'تصنيف الشورت'),
                items: _shortCategories.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (v) => setState(() => _category = v ?? 'حسب مزاج المستخدم'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tags,
                maxLength: 500,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'الوسوم (اختياري)',
                  hintText: 'ضحك، رسوم متحركة، تحدي',
                  helperText: 'افصل بين الوسوم بفاصلة أو مسافة؛ حتى 20 وسمًا',
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _publishing ? null : _publish, icon: const Icon(Icons.publish_rounded), label: Text(_publishing ? 'جاري النشر...' : 'نشر'))),
          ]))),
          const SizedBox(height: 16),
          const Text('Your content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _repo.watchRecentPosts(uid),
            builder: (context, snap) {
              if (snap.hasError) return Text('تعذر تحميل المحتوى: ${snap.error}');
              final posts = snap.data ?? const <Map<String, dynamic>>[];
              if (posts.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لسه ما نشرت محتوى. ابدأ بأول منشور.')));
              return Column(children: posts.map((post) {
                final id = post['id'].toString();
                final text = post['text'].toString();
                final likes = (post['likes'] as num?)?.toInt() ?? 0;
                return Card(child: ListTile(
                  title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('$likes إعجاب • ${post['mediaType'] ?? 'none'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      try { await _repo.delete(uid, id); _refreshStats(); }
                      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحذف: $e'))); }
                    },
                  ),
                ));
              }).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Icon(icon), const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]))),
  );
}
