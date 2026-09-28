import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auren_entertainment_output_screen.dart';
import 'entertainment_detail_screen.dart';

import '../../../services/entertainment/entertainment_repository.dart';
import '../../../services/entertainment/auren_entertainment_orchestrator.dart';

class AurenEntertainmentJobDetailScreen extends StatelessWidget {
  final String jobId;
  const AurenEntertainmentJobDetailScreen({super.key, required this.jobId});

  String _queueLabel(String queueStatus) {
    switch (queueStatus) {
      case 'queued': return 'في قائمة الانتظار';
      case 'processing': return 'المعالج يعمل على المهمة';
      case 'waiting_provider': return 'بانتظار مزوّد حقيقي';
      default: return '';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'planning': return 'التخطيط';
      case 'generating': return 'التوليد';
      case 'processing': return 'المعالجة';
      case 'ready': return 'جاهز';
      case 'failed': return 'فشل';
      case 'cancelled': return 'ملغاة';
      default: return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'planning': return Icons.assignment_rounded;
      case 'generating': return Icons.auto_awesome_rounded;
      case 'processing': return Icons.settings_suggest_rounded;
      case 'ready': return Icons.check_circle_rounded;
      case 'failed': return Icons.error_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.timelapse_rounded;
    }
  }

  Future<void> _publish(BuildContext context, String uid) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('publishEntertainmentOutput');
      final result = await callable.call({'jobId': jobId});
      if (!context.mounted) return;
      final data = Map<String, dynamic>.from(result.data as Map);
      final publishedItemId = data['itemId']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['alreadyPublished'] == true
                ? 'المحتوى منشور بالفعل في Entertainment.'
                : 'تم نشر المحتوى في Entertainment.',
          ),
        ),
      );
      if (publishedItemId.isNotEmpty && context.mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AurenEntertainmentDetailScreen(itemId: publishedItemId)),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'تعذر نشر المحتوى.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر نشر المحتوى حالياً.')),
      );
    }
  }

  Future<void> _startProvider(BuildContext context, String uid) async {
    final orchestration = await AurenEntertainmentJobOrchestrator().start(uid, jobId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        orchestration.accepted
            ? 'بدأت المهمة عبر ${orchestration.provider}.'
            : orchestration.message,
      )),
    );
  }

  Future<void> _retry(BuildContext context, String uid) async {
    await EntertainmentRepository().retryEntertainmentJob(uid, jobId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أُعيدت المهمة إلى مرحلة التخطيط.')),
      );
    }
  }

  Future<void> _cancel(BuildContext context, String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء مهمة الإنتاج؟'),
        content: const Text('لن يتم حذف المسودة أو المهمة. سيتم حفظها كملغاة ويمكن مراجعتها لاحقاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('تراجع')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('إلغاء المهمة')),
        ],
      ),
    );
    if (ok != true) return;
    await EntertainmentRepository().cancelEntertainmentJob(uid, jobId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء المهمة.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول لمتابعة مشروعك.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الإنتاج')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: EntertainmentRepository().watchEntertainmentCreationJob(uid, jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final job = snapshot.data;
          if (job == null) {
            return const Center(child: Text('مهمة الإنتاج غير موجودة.'));
          }

          final status = job['status']?.toString() ?? 'planning';
          final queueStatus = job['queueStatus']?.toString() ?? '';
          final queueLabel = _queueLabel(queueStatus);
          final progress = ((job['progress'] as num?)?.toInt() ?? 0).clamp(0, 100);
          final plan = job['plan'] is List
              ? (job['plan'] as List).map((e) => e.toString()).toList()
              : <String>[];
          final assets = job['assets'] is List
              ? (job['assets'] as List).map((e) => e.toString()).toList()
              : <String>[];
          final currentIndex = plan.isEmpty
              ? 0
              : ((progress / 100) * plan.length).floor().clamp(0, plan.length - 1);
          final canCancel = status == 'planning' || status == 'generating' || status == 'processing';
          final canRetry = status == 'failed';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              _summaryCard(context, job, status, progress),
              if (queueLabel.isNotEmpty) ...[
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: Icon(
                      queueStatus == 'waiting_provider'
                          ? Icons.cloud_off_rounded
                          : Icons.sync_rounded,
                    ),
                    title: Text(queueLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      job['providerMessage']?.toString() ??
                          'حالة قائمة الانتظار تُدار من خادم AUREN.',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (status == 'planning')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _startProvider(context, uid),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('بدء التنفيذ مع AUREN AI'),
                  ),
                ),
              if (status == 'planning') const SizedBox(height: 12),
              if (canCancel || canRetry)
                Row(
                  children: [
                    if (canCancel)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancel(context, uid),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('إلغاء'),
                        ),
                      ),
                    if (canCancel && canRetry) const SizedBox(width: 10),
                    if (canRetry)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _retry(context, uid),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ),
                  ],
                ),
              if (canCancel || canRetry) const SizedBox(height: 18),
              _sectionTitle('مراحل الإنتاج'),
              const SizedBox(height: 8),
              ...plan.asMap().entries.map((entry) {
                final index = entry.key;
                final title = entry.value;
                final completed = progress >= ((index + 1) / plan.length * 100).ceil();
                final active = index == currentIndex && !completed && status != 'failed' && status != 'cancelled';
                return _stepCard(
                  context,
                  index: index,
                  title: title,
                  completed: completed || status == 'ready',
                  active: active,
                );
              }),
              if (plan.isEmpty)
                const Card(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('لا توجد مراحل محفوظة لهذه المهمة.'),
                )),
              const SizedBox(height: 18),
              _sectionTitle('الأصول المطلوبة'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      ...assets.map((asset) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.radio_button_unchecked_rounded),
                        title: Text(_assetLabel(asset)),
                        subtitle: const Text('بانتظار طبقة الإنتاج/المزوّد'),
                      )),
                      if (assets.isEmpty)
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text('لم تُسجل أصول مطلوبة لهذه المهمة بعد.'),
                        ),
                    ],
                  ),
                ),
              ),
              if (status == 'ready') ...[
                const SizedBox(height: 18),
                _sectionTitle('الحزمة النهائية'),
                const SizedBox(height: 8),
                FutureBuilder<Map<String, dynamic>?>(
                  future: EntertainmentRepository().getFinalEpisodePackage(jobId),
                  builder: (context, packageSnapshot) {
                    if (packageSnapshot.connectionState == ConnectionState.waiting) {
                      return const Card(child: ListTile(leading: CircularProgressIndicator(), title: Text('جاري تجهيز الحزمة النهائية…')));
                    }
                    if (packageSnapshot.hasError || packageSnapshot.data == null) {
                      return const Card(child: ListTile(leading: Icon(Icons.hourglass_empty_rounded), title: Text('الحزمة النهائية لم تصبح متاحة بعد'), subtitle: Text('سيتم عرض الحلقات والأصول تلقائياً عند اكتمالها.')));
                    }
                    final data = packageSnapshot.data!;
                    final pkg = data['package'] is Map ? Map<String, dynamic>.from(data['package'] as Map) : <String, dynamic>{};
                    final episodes = pkg['episodes'] is List ? pkg['episodes'] as List : const [];
                    final assets = pkg['availableAssets'] is List ? (pkg['availableAssets'] as List).map((e) => e.toString()).toList() : const <String>[];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(pkg['title']?.toString().isNotEmpty == true ? pkg['title'].toString() : 'مسلسل AUREN', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('${episodes.length} حلقة • الحزمة v${data['packageVersion'] ?? 1}'),
                          if (assets.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 8, children: assets.map((asset) => Chip(avatar: const Icon(Icons.check_rounded, size: 16), label: Text(_assetLabel(asset))).toList()),
                          ],
                          const SizedBox(height: 10),
                          ...episodes.take(20).map((episode) {
                            final e = episode is Map ? Map<String, dynamic>.from(episode) : <String, dynamic>{};
                            final n = e['episodeNumber'] ?? '?';
                            final media = e['media'] is Map ? Map<String, dynamic>.from(e['media'] as Map) : <String, dynamic>{};
                            final hasVideo = media['video'] is Map || media['video']?.toString().isNotEmpty == true;
                            final hasTrailer = media['trailer'] is Map || media['trailer']?.toString().isNotEmpty == true;
                            final episodeNumber = int.tryParse(n.toString()) ?? 1;
                            final episodeIndex = episodes.indexOf(episode);
                            final seriesTitle = pkg['title']?.toString() ?? '';
                            final baseSubtitle = [if (hasVideo) 'فيديو', if (media['audio'] != null) 'صوت', if (media['subtitles'] != null) 'AR/EN', if (hasTrailer) 'Trailer'].join(' • ');
                            return FutureBuilder<Map<String, dynamic>?>(
                              future: EntertainmentRepository().getSeriesWatchProgress(uid, jobId, episodeNumber),
                              builder: (context, progressSnapshot) {
                                final saved = progressSnapshot.data;
                                final progress = (saved?['progress'] as num?)?.toDouble() ?? 0;
                                final position = (saved?['positionSeconds'] as num?)?.toInt() ?? 0;
                                final hasResume = hasVideo && position > 5 && progress > 0.02 && progress < 0.98;
                                final subtitle = hasResume
                                    ? '$baseSubtitle • متابعة من ${_formatSeconds(position)} (${(progress * 100).round()}%)'
                                    : baseSubtitle;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(child: Text('$n')),
                                  title: Text('الحلقة $n', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                                  trailing: hasVideo ? const Icon(Icons.play_circle_fill_rounded) : null,
                                  onTap: hasVideo ? () {
                                    final video = media['video'];
                                    final output = video is Map ? Map<String, dynamic>.from(video) : {'url': video.toString(), 'type': 'video', 'mimeType': 'video/mp4'};
                                    final nextIndex = episodeIndex + 1;
                                    final hasNext = nextIndex < episodes.length && nextIndex < 20;
                                    Future<void> openNextEpisode() async {
                                      if (!hasNext || !context.mounted) return;
                                      final nextRaw = episodes[nextIndex];
                                      final next = nextRaw is Map ? Map<String, dynamic>.from(nextRaw) : <String, dynamic>{};
                                      final nextNumber = int.tryParse(next['episodeNumber']?.toString() ?? '') ?? (episodeNumber + 1);
                                      final nextMedia = next['media'] is Map ? Map<String, dynamic>.from(next['media'] as Map) : <String, dynamic>{};
                                      final nextVideo = nextMedia['video'];
                                      if (nextVideo == null) return;
                                      final nextOutput = nextVideo is Map ? Map<String, dynamic>.from(nextVideo) : {'url': nextVideo.toString(), 'type': 'video', 'mimeType': 'video/mp4'};
                                      final nextThumbnail = nextMedia['thumbnail'];
                                      final nextPreviewUrl = nextThumbnail is Map ? nextThumbnail['url']?.toString() ?? '' : nextThumbnail?.toString() ?? '';
                                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AurenEntertainmentOutputScreen(
                                        output: nextOutput,
                                        title: seriesTitle,
                                        episodeLabel: 'الحلقة $nextNumber',
                                        onNextEpisode: nextIndex + 1 < episodes.length && nextIndex + 1 < 20 ? openNextEpisode : null,
                                        nextEpisodeLabel: nextIndex + 1 < episodes.length && nextIndex + 1 < 20 ? 'الحلقة ' + (nextNumber + 1) : null,
                                        nextPreviewUrl: nextIndex + 1 < episodes.length && nextIndex + 1 < 20
                                            ? (() {
                                                final raw = episodes[nextIndex + 1];
                                                final item = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                                                final m = item['media'] is Map ? Map<String, dynamic>.from(item['media'] as Map) : <String, dynamic>{};
                                                final t = m['thumbnail'];
                                                return t is Map ? t['url']?.toString() ?? '' : t?.toString() ?? '';
                                              })()
                                            : null,
                                        watchUid: uid,
                                        watchJobId: jobId,
                                        watchEpisodeNumber: nextNumber,
                                        watchTitle: seriesTitle,
                                      )));
                                    }
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenEntertainmentOutputScreen(
                                      output: output,
                                      title: seriesTitle,
                                      episodeLabel: 'الحلقة $episodeNumber',
                                      watchUid: uid,
                                      watchJobId: jobId,
                                      watchEpisodeNumber: episodeNumber,
                                      onNextEpisode: hasNext ? openNextEpisode : null,
                                      watchTitle: seriesTitle,
                                    )));
                                  } : null,
                                );
                              },
                            );
                          }),
                        ]),
                      ),
                    );
                  },
                ),
              ],
              if (status == 'ready' && job['providerResult'] is Map &&
                  (job['providerResult'] as Map).isNotEmpty) ...[
                const SizedBox(height: 18),
                _sectionTitle('الناتج'),
                const SizedBox(height: 8),
                _outputCard(
                  context,
                  Map<String, dynamic>.from(job['providerResult'] as Map),
                  published: job['publishedItemId']?.toString().isNotEmpty == true,
                  publishedItemId: job['publishedItemId']?.toString() ?? '',
                  onPublish: () => _publish(context, uid),
                ),
              ],
              const SizedBox(height: 18),
              _sectionTitle('ملخص المشروع'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${job['mode'] ?? 'مشروع'} • ${job['mood'] ?? ''} • ${job['length'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Text(job['idea']?.toString() ?? ''),
                      const SizedBox(height: 12),
                      Text('المزوّد: ${job['provider'] ?? 'auren_ai'}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('تم تنفيذ المهمة عبر طبقة المزوّد الآمنة. الناتج الظاهر هنا محفوظ من خادم AUREN.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _outputCard(BuildContext context, Map<String, dynamic> output, {required bool published, required String publishedItemId, required VoidCallback onPublish}) {
    final type = output['type']?.toString() ?? 'output';
    final url = output['url']?.toString() ?? '';
    final text = output['text']?.toString() ?? '';
    final mime = output['mimeType']?.toString() ?? '';
    final isVideo = type == 'video' || mime.startsWith('video/');
    final isAudio = type == 'audio' || mime.startsWith('audio/');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isVideo
                      ? Icons.video_library_rounded
                      : isAudio
                          ? Icons.music_note_rounded
                      : type == 'image'
                          ? Icons.image_rounded
                          : Icons.auto_awesome_rounded,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isVideo
                        ? 'فيديو جاهز'
                        : isAudio
                            ? 'موسيقى جاهزة'
                        : type == 'image'
                            ? 'صورة جاهزة'
                            : 'ناتج جاهز',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(text),
            ],
            if (url.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AurenEntertainmentOutputScreen(
                          output: output,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    isVideo || isAudio
                        ? Icons.play_circle_fill_rounded
                        : type == 'image'
                            ? Icons.visibility_rounded
                            : Icons.open_in_new_rounded,
                  ),
                  label: Text(
                    isVideo
                        ? 'تشغيل الفيديو'
                        : isAudio
                            ? 'تشغيل الموسيقى'
                        : type == 'image'
                            ? 'عرض الصورة'
                            : 'فتح الناتج',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!published)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onPublish,
                    icon: const Icon(Icons.public_rounded),
                    label: const Text('نشر في Entertainment'),
                  ),
                )
              else ...[
                const Row(
                  children: [
                    Icon(Icons.public_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('منشور في Entertainment', style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
                if (publishedItemId.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AurenEntertainmentDetailScreen(
                            itemId: publishedItemId,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('فتح المحتوى المنشور'),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 6),
              Text(
                'الناتج محفوظ في تخزين AUREN، ويمكن تشغيله أو مشاركته من هنا.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, Map<String, dynamic> job, String status, int progress) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(status), size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${job['mode'] ?? 'مشروع'} • ${_statusLabel(status)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                Text('${progress}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: progress / 100, minHeight: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
  );

  Widget _stepCard(
    BuildContext context, {
    required int index,
    required String title,
    required bool completed,
    required bool active,
  }) {
    final icon = completed
        ? Icons.check_circle_rounded
        : active
            ? Icons.play_circle_fill_rounded
            : Icons.radio_button_unchecked_rounded;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon, size: 20)),
        title: Text(title, style: TextStyle(fontWeight: active || completed ? FontWeight.w800 : FontWeight.w500)),
        subtitle: Text(completed ? 'مكتملة' : active ? 'المرحلة الحالية' : 'في الانتظار'),
        trailing: Text('${index + 1}', style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$secs' : '$minutes:$secs';
  }

  String _assetLabel(String asset) {
    const labels = {
      'lyrics': 'الكلمات',
      'music': 'الموسيقى',
      'vocals': 'الصوت / الأداء',
      'artwork': 'الغلاف الفني',
      'script': 'السيناريو',
      'storyboard': 'Storyboard',
      'video': 'الفيديو',
      'audio': 'الصوت',
      'thumbnail': 'الصورة المصغرة',
      'voice': 'التسجيل الصوتي',
      'cover': 'الغلاف',
      'description': 'الوصف',
      'world': 'العالم',
      'characters': 'الشخصيات',
      'locations': 'الأماكن',
      'missions': 'المهام',
      'story': 'القصة',
      'scenes': 'المشاهد',
    };
    return labels[asset] ?? asset;
  }
}
