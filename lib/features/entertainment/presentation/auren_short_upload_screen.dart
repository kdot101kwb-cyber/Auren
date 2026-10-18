import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Direct device-to-AUREN publishing for vertical Shorts.
class AurenShortUploadScreen extends StatefulWidget {
  const AurenShortUploadScreen({super.key});

  @override
  State<AurenShortUploadScreen> createState() => _AurenShortUploadScreenState();
}

class _AurenShortUploadScreenState extends State<AurenShortUploadScreen> {
  static const _maxBytes = 25 * 1024 * 1024;
  static const _maxDuration = Duration(seconds: 180);
  static const _categories = <String>[
    'كرتون',
    'كوميديا',
    'فلوقات',
    'موسيقى',
    'ألعاب',
    'تعليمي',
    'رياضة',
    'منوعات',
  ];
  static const _moods = <String>[
    'تسلية',
    'ضحك',
    'موسيقى',
    'أفلام',
    'Gaming',
    'اكتشاف',
  ];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _video;
  String _category = 'كوميديا';
  String _mood = 'تسلية';
  bool _busy = false;
  double _progress = 0;
  String? _error;

  Future<void> _pickVideo() async {
    if (_busy) return;
    try {
      final selected = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: _maxDuration,
      );
      if (selected == null || !mounted) return;

      final extension = selected.name.split('.').last.toLowerCase();
      if (extension != 'mp4') {
        setState(() {
          _error = 'اختار فيديو بصيغة MP4 عشان يشتغل على أكبر عدد من الأجهزة.';
          _video = null;
        });
        return;
      }

      final bytes = await selected.length();
      if (bytes <= 0 || bytes > _maxBytes) {
        setState(() {
          _error = 'حجم الفيديو لازم يكون أكبر من صفر وأقل من 25 ميجابايت.';
          _video = null;
        });
        return;
      }

      final controller = VideoPlayerController.file(File(selected.path));
      try {
        await controller.initialize();
        if (controller.value.duration > _maxDuration) {
          if (mounted) {
            setState(() {
              _error = 'مدة الشورت لازم تكون 3 دقائق أو أقل.';
              _video = null;
            });
          }
          return;
        }
      } finally {
        await controller.dispose();
      }

      if (!mounted) return;
      setState(() {
        _video = selected;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذّر فتح الفيديو. جرّب ملف MP4 آخر.');
      }
    }
  }

  Future<void> _publish() async {
    final user = FirebaseAuth.instance.currentUser;
    final video = _video;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (user == null) {
      setState(() => _error = 'سجّل الدخول أولاً عشان تنشر شورت.');
      return;
    }
    if (video == null) {
      setState(() => _error = 'اختار فيديو MP4 أولاً.');
      return;
    }
    if (title.isEmpty || title.length > 160) {
      setState(() => _error = 'اكتب عنواناً من 1 إلى 160 حرفاً.');
      return;
    }
    if (description.length > 3000) {
      setState(() => _error = 'الوصف أطول من الحد المسموح (3000 حرف).');
      return;
    }

    setState(() {
      _busy = true;
      _progress = 0;
      _error = null;
    });

    final db = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    final itemRef = db.collection('entertainment_items').doc();
    final objectRef = storage.ref('shorts/${user.uid}/${itemRef.id}.mp4');
    UploadTask? task;
    StreamSubscription<TaskSnapshot>? progressSubscription;
    var uploaded = false;

    try {
      task = objectRef.putFile(
        File(video.path),
        SettableMetadata(contentType: 'video/mp4', customMetadata: {
          'ownerUid': user.uid,
          'shortId': itemRef.id,
        }),
      );
      progressSubscription = task.snapshotEvents.listen((snapshot) {
        if (!mounted) return;
        final total = snapshot.totalBytes;
        setState(() => _progress =
            total <= 0 ? 0 : snapshot.bytesTransferred / total);
      });
      await task;
      uploaded = true;
      final downloadUrl = await objectRef.getDownloadURL();

      final channelRef = db.collection('content_channels').doc(user.uid);
      final displayName = user.displayName?.trim() ?? '';
      final channel = await channelRef.get();
      if (!channel.exists) {
        await channelRef.set({
          'ownerId': user.uid,
          'name': displayName.isEmpty
              ? 'قناة AUREN'
              : (displayName.length > 100
                  ? displayName.substring(0, 100)
                  : displayName),
          'description': 'قناة منشئ محتوى على AUREN.',
          'subscribers': 0,
          'public': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (channel.data()?['ownerId'] != user.uid) {
        throw StateError('تعذر التحقق من ملكية قناة النشر.');
      }

      await itemRef.set({
        'title': title,
        'description': description,
        'mediaUrl': downloadUrl,
        'mediaKind': 'video',
        'imageUrl': '',
        'type': 'Short',
        'creatorId': user.uid,
        'ownerId': user.uid,
        'authorId': user.uid,
        'channelId': user.uid,
        'visibility': 'public',
        'createdAt': FieldValue.serverTimestamp(),
        'publishedAt': FieldValue.serverTimestamp(),
        'category': _category,
        'contentCategory': _category,
        'tags': <String>[],
        'genres': <String>[_category],
        'language': 'ar',
        'country': '',
        'moods': <String>[_mood],
        'likes': 0,
        'views': 0,
        'comments': 0,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر الشورت بنجاح 🎉')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (uploaded) {
        try {
          await objectRef.delete();
        } catch (_) {
          // Keep the original publish error visible; cleanup is best-effort.
        }
      }
      if (mounted) {
        setState(() {
          _error =
              'ما قدرنا ننشر الشورت. راجع اتصال الإنترنت وصلاحيات Firebase ثم حاول مرة أخرى.';
        });
      }
    } finally {
      await progressSubscription?.cancel();
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('نشر شورت جديد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.video_library_outlined, size: 32),
                SizedBox(height: 8),
                Text(
                  'فيديوك، جمهورك',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('MP4 • حتى 3 دقائق • حتى 25 ميجابايت'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickVideo,
            icon: const Icon(Icons.video_file_outlined),
            label: Text(_video == null ? 'اختيار فيديو من الجهاز' : 'تغيير الفيديو'),
          ),
          if (_video != null) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(_video!.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: const Text('جاهز للنشر'),
              trailing: IconButton(
                tooltip: 'إزالة الفيديو',
                onPressed: _busy ? null : () => setState(() => _video = null),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            maxLength: 160,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'عنوان الشورت',
              hintText: 'اكتب عنواناً يشد الانتباه',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLength: 3000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'الوصف (اختياري)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'تصنيف الشورت',
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: _busy
                ? null
                : (value) {
                    if (value != null) setState(() => _category = value);
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _mood,
            decoration: const InputDecoration(
              labelText: 'المزاج',
              border: OutlineInputBorder(),
            ),
            items: _moods
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: _busy
                ? null
                : (value) {
                    if (value != null) setState(() => _mood = value);
                  },
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            const SizedBox(height: 8),
            Text(
              _progress > 0
                  ? 'جاري رفع الفيديو ${(_progress * 100).round()}%'
                  : 'جاري تجهيز النشر...',
              textAlign: TextAlign.center,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _publish,
            icon: const Icon(Icons.publish_rounded),
            label: Text(_busy ? 'جاري النشر...' : 'نشر الشورت'),
          ),
        ],
      ),
    );
  }
}
