import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'auren_audio_player_screen.dart';

/// First-pass Rap Arena: discovers existing public music and helps creators
/// prepare original freestyle ideas. Battle submissions and voting are a later
/// backend-backed phase and are intentionally not simulated here.
class AurenRapArenaScreen extends StatefulWidget {
  const AurenRapArenaScreen({super.key});

  @override
  State<AurenRapArenaScreen> createState() => _AurenRapArenaScreenState();
}

class _AurenRapArenaScreenState extends State<AurenRapArenaScreen> {
  static const _challenges = <({String title, String description, String prompt})>[
    (
      title: 'Freestyle in 60 Seconds',
      description: 'اختار موضوعاً وابنِ مقطعاً أصلياً في دقيقة.',
      prompt: 'ساعدني في تحدي راب Freestyle لمدة 60 ثانية. اقترح موضوعاً أصلياً، قوافي متعددة، وبنية للمقطع بدون تقليد فنان حقيقي.'
    ),
    (
      title: 'Storytelling Rap',
      description: 'حوّل موقفاً أو تجربة إلى قصة بإيقاع وقافية.',
      prompt: 'ساعدني في كتابة مخطط أغنية راب قصصية أصلية: بداية قوية، تفاصيل واضحة، قوافٍ طبيعية، ونهاية مؤثرة. اسألني عن القصة قبل كتابة تفاصيل شخصية.'
    ),
    (
      title: 'Wordplay Challenge',
      description: 'تلاعب بالكلمات والصور البلاغية والمعاني.',
      prompt: 'درّبني على Wordplay في الراب. أعطني كلمة أو موضوعاً، ثم ساعدني في ابتكار قوافٍ وصور بلاغية أصلية باللغة التي أختارها.'
    ),
    (
      title: 'Sudan to the World',
      description: 'امزج هويتك المحلية برؤية موسيقية عالمية.',
      prompt: 'ساعدني في تصميم فكرة راب أصلية تمزج إشارات ثقافية سودانية أختارها مع هيب هوب عالمي، مع احترام اللهجة والهوية وعدم افتراض أن كل المستخدمين يفضلون اللهجة السودانية.'
    ),
  ];

  final EntertainmentRepository _repository = EntertainmentRepository();

  void _openAi(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(initialPrompt: prompt),
      ),
    );
  }

  bool _isRap(AurenEntertainmentItem item) {
    final text = '${item.title} ${item.description} ${item.artistName} ${item.genres.join(' ')}'
        .toLowerCase();
    return text.contains('rap') ||
        text.contains('hip hop') ||
        text.contains('hip-hop') ||
        text.contains('freestyle') ||
        text.contains('راب') ||
        text.contains('هيب هوب');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Rap Arena'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [colors.primaryContainer, colors.tertiaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mic_external_on_rounded, size: 42),
                SizedBox(height: 10),
                Text(
                  'Find your voice.',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Rap • Hip Hop • Freestyle • Storytelling',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'اكتشف موسيقى الراب، حضّر فكرتك، وطوّر أسلوبك بصوتك وهويتك.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'ابدأ تحدياً إبداعياً',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final challenge in _challenges)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.bolt_rounded),
                ),
                title: Text(
                  challenge.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(challenge.description),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openAi(challenge.prompt),
              ),
            ),
          const SizedBox(height: 14),
          const Text(
            'اكتشف الراب والهيب هوب',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<AurenEntertainmentItem>>(
            stream: _repository.watchItems(type: 'Music'),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('تعذر تحميل الموسيقى الآن. حاول مرة أخرى لاحقاً.'),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final tracks = (snapshot.data ?? const <AurenEntertainmentItem>[])
                  .where((item) => item.mediaUrl.isNotEmpty && _isRap(item))
                  .toList();
              if (tracks.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'لا توجد مقاطع راب منشورة في المكتبة حالياً. يمكن للفنانين إضافة محتوى مرخّص عندما تتوفر واجهة النشر.',
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final track in tracks)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: track.imageUrl.isEmpty
                              ? null
                              : NetworkImage(track.imageUrl),
                          child: track.imageUrl.isEmpty
                              ? const Icon(Icons.music_note_rounded)
                              : null,
                        ),
                        title: Text(track.title),
                        subtitle: Text(
                          track.artistName.isEmpty
                              ? track.description
                              : track.artistName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.play_circle_fill_rounded),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AurenAudioPlayerScreen(item: track),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openAi(
              'ساعدني في تطوير هويتي كفنان راب داخل AUREN: الاسم الفني، الرسالة، الأسلوب، وخطة تدريب أسبوعية تناسب وقتي وميزانيتي. لا تقلّد فناناً حقيقياً.',
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('ابنِ هويتك الفنية مع AUREN AI'),
          ),
          const SizedBox(height: 8),
          const Text(
            'ملاحظة: هذه الدفعة تضيف واجهة Rap Arena واكتشاف المقاطع والتحديات الإبداعية. نشر المشاركات والتصويت وترتيب المتنافسين يحتاج إلى المرحلة الخلفية وقواعد أمان منفصلة.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
