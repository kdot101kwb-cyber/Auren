import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'auren_audio_player_screen.dart';
import 'auren_mini_player.dart';
import 'auren_podcasts_screen.dart';
import 'auren_radio_screen.dart';
import 'auren_music_queue_screen.dart';
import 'auren_smart_music_screen.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';

class AurenMusicHubScreen extends StatelessWidget {
  const AurenMusicHubScreen({super.key});

  void _ai(BuildContext context, String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = EntertainmentRepository();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Music AI',
            onPressed: () => _ai(
              context,
              'ساعدني كـ AUREN Music AI. اختر لي موسيقى مناسبة لمزاجي ووقتي، أو ساعدني في إنشاء فكرة أغنية أصلية بدون تقليد صوت فنان حقيقي.',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: 'Music'),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <AurenEntertainmentItem>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _hero(context),
              const SizedBox(height: 18),
              _sectionTitle('استمع بطريقتك'),
              _actions(context),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: AurenMusicPlayerController.instance,
                builder: (context, _) {
                  final item = AurenMusicPlayerController.instance.item;
                  if (item == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.history_rounded),
                        title: const Text('Continue Listening'),
                        subtitle: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAudioPlayerScreen())),
                      ),
                    ),
                  );
                },
              ),
              _sectionTitle('Music & Podcasts'),
              if (snapshot.hasError)
                Text('تعذر تحميل الموسيقى: ${snapshot.error}')
              else if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'لا توجد موسيقى مضافة بعد. يمكنك استخدام Music AI لإنشاء فكرة أو اكتشاف نوع موسيقى مناسب.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...items.map((item) => ListTile(
                      leading: item.imageUrl.isEmpty
                          ? const CircleAvatar(child: Icon(Icons.music_note))
                          : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
                      title: Text(item.title),
                      subtitle: Text(item.description, maxLines: 2),
                      onTap: item.mediaUrl.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'إضافة إلى Queue',
                            icon: const Icon(Icons.queue_music_rounded),
                            onPressed: item.mediaUrl.isEmpty
                                ? null
                                : () => AurenMusicPlayerController.instance.addToQueue(item),
                          ),
                          if (uid != null)
                            IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () async {
                                  await repo.save(uid, item.id);
                                  await repo.trackMusicAction(uid, item.id, action: 'save', contentType: item.type);
                                },
                            ),
                        ],
                      ),
                    )),
            ],
          );
        },
          ),
          const AurenMiniPlayer(),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.tertiaryContainer,
            ],
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.music_note_rounded, size: 42),
            SizedBox(height: 8),
            Text('Listen. Create. Discover.',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Music • Radio • Podcasts • Original AI'),
          ],
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      );

  Widget _actions(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _action(context, Icons.auto_awesome, 'AI Music',
              'Smart Music',
              'ساعدني في إنشاء أغنية أصلية: فكرة، كلمات، بنية وموسيقى مناسبة، بدون تقليد صوت فنان حقيقي.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSmartMusicScreen()))),
          _action(context, Icons.radio, 'Radio', 'محطات واكتشاف',
              'اقترح لي تجربة Radio مناسبة لذوقي ووقتي.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenRadioScreen()))),
          _action(context, Icons.podcasts, 'Podcasts', 'بودكاست ذكي',
              'اقترح لي بودكاست مناسباً لموضوعي ووقتي.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenPodcastsScreen()))),
          _action(context, Icons.playlist_play, 'Playlist',
              'Queue + History',
              'أنشئ لي Playlist ذكية حسب مزاجي ووقتي ونشاطي.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenMusicQueueScreen()))),
        ],
      );

  Widget _action(BuildContext context, IconData icon, String title,
      String subtitle, String prompt, {VoidCallback? onTap}) {
    return SizedBox(
      width: 160,
      child: Card(
        child: InkWell(
          onTap: onTap ?? () => _ai(context, prompt),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
