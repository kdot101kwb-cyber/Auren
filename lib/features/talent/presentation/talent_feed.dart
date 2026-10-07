import 'package:flutter/material.dart';
import '../../../core/models/talent.dart';
import '../../../services/talent/talent_repository.dart';
import 'talent_star_profile_screen.dart';

class AurenTalentFeed extends StatelessWidget {
  final String uid;
  const AurenTalentFeed({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final repo = TalentRepository();
    return StreamBuilder<List<AurenTalent>>(
      stream: repo.watchPublic(query: '', skill: '', sport: '', evidenceOnly: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.error_outline),
              title: Text('تعذر تحميل Talent Feed'),
              subtitle: Text('حاول مرة أخرى لاحقاً.'),
            ),
          );
        }
        final talents = snapshot.data ?? const <AurenTalent>[];
        if (talents.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dynamic_feed_outlined),
                      SizedBox(width: 8),
                      Text('Talent Feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('أول محتوى سيظهر هنا عندما تبدأ المواهب بالنشر داخل AUREN.'),
                ],
              ),
            ),
          );
        }

        final visible = talents.take(8).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dynamic_feed_outlined),
                    SizedBox(width: 8),
                    Expanded(child: Text('Talent Feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('مواهب وأعمال واكتشافات مناسبة للاستكشاف والتواصل.'),
                const SizedBox(height: 10),
                ...visible.map((talent) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person_search_outlined)),
                  title: Text(talent.displayName),
                  subtitle: Text([
                    talent.category,
                    talent.discipline,
                    talent.level,
                    if (talent.skills.isNotEmpty) talent.skills.take(2).join(' • '),
                  ].where((v) => v.trim().isNotEmpty).join(' • ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AurenTalentStarProfileScreen(talent: talent)),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}