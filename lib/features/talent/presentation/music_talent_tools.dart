import 'package:flutter/material.dart';
import '../../../services/talent/music_talent_catalog.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenMusicTalentTools extends StatelessWidget {
  const AurenMusicTalentTools({super.key});



  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎵 Music Talent',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'أدوات متخصصة للمغنين والعازفين وكتاب الأغاني والملحنين والمنتجين والـDJ داخل Talent.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                AurenMusicTalentCatalog.all.length,
                (i) => ActionChip(
                  avatar: const Icon(Icons.music_note, size: 16),
                  label: Text(AurenMusicTalentCatalog.all[i].name),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessengerScreen(initialPrompt: 'ساعدني في ${AurenMusicTalentCatalog.all[i].name}: ${AurenMusicTalentCatalog.all[i].description}'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
