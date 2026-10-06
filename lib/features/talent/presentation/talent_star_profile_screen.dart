import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/talent.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'talent_badges_screen.dart';
import 'talent_performance_screen.dart';
import 'talent_claim_screen.dart';
import 'talent_verification_screen.dart';
import 'talent_coach_screen.dart';
import '../../../services/talent/talent_score_service.dart';

class AurenTalentStarProfileScreen extends StatelessWidget {
  final AurenTalent talent;
  const AurenTalentStarProfileScreen({super.key, required this.talent});

  @override
  Widget build(BuildContext context) {
    final sports = talent.sports.isEmpty && talent.sport.isNotEmpty
        ? [talent.sport]
        : talent.sports;
    final score = TalentScoreService.calculate(
      displayName: talent.displayName,
      bio: talent.bio,
      sports: sports,
      skills: talent.skills,
      achievements: talent.achievements,
      goals: talent.goals,
      verificationEvidence: talent.verificationEvidence,
      level: talent.level,
      discipline: talent.discipline,
      city: talent.city,
      country: talent.country,
    );
    final location = [talent.city, talent.country]
        .where((v) => v.trim().isNotEmpty)
        .join(' • ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Profile'),
        actions: [
          IconButton(
            tooltip: 'AUREN AI',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessengerScreen(
                  initialPrompt:
                      'حلل ملف الرياضي ' + talent.displayName + ' اعتماداً فقط على البيانات الظاهرة: الرياضة، المهارات، الإنجازات، الأهداف والأداء. وضّح أي بيانات غير متوفرة.',
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                children: [
                  const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
                  const SizedBox(height: 12),
                  Text(talent.displayName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                  if (location.isNotEmpty) ...[const SizedBox(height: 5), Text(location)],
                  if (sports.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: sports.map((s) => Chip(label: Text(s))).toList(),
                    ),
                  ],
                  if (talent.level.isNotEmpty || talent.discipline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      [talent.discipline, talent.level].where((v) => v.trim().isNotEmpty).join(' • '),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _section('About', talent.bio),
          _talentScoreCard(score),
          _profileSummaryCard(),
          _profileTrustCard(),
          if (talent.category.isNotEmpty) _infoCard('Category', talent.category, Icons.category_outlined),
          if (talent.skills.isNotEmpty) _chipsSection('Skills', talent.skills),
          if (talent.achievements.isNotEmpty) _chipsSection('Achievements', talent.achievements),
          if (talent.goals.isNotEmpty) _chipsSection('Goals', talent.goals),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Talent actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessengerScreen(
                          initialPrompt: 'ساعدني أفهم ملف ' + talent.displayName + ' وأفضل طريقة للتواصل معه بناءً على البيانات المتاحة فقط.',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Connect with AUREN AI'),
                  ),
                  const SizedBox(height: 8),
                  if (FirebaseAuth.instance.currentUser?.uid != talent.ownerId)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AurenTalentClaimScreen(talentId: talent.id, talentName: talent.displayName)),
                      ),
                      icon: const Icon(Icons.assignment_ind_outlined),
                      label: const Text('Claim this profile'),
                    ),
                  if (FirebaseAuth.instance.currentUser?.uid == talent.ownerId) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AurenTalentVerificationScreen(
                            talentId: talent.id,
                            ownerId: talent.ownerId,
                            currentEvidence: talent.verificationEvidence,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Talent Verification'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AurenTalentCoachScreen(
                            talentId: talent.id,
                            sport: talent.sport,
                            level: talent.level,
                            sports: sports,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.sports_outlined),
                      label: const Text('مدربي الشخصي'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AurenTalentPerformanceScreen(
                          sport: talent.sport.isEmpty ? talent.category : talent.sport,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.insights_outlined),
                    label: const Text('Performance'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AurenTalentBadgesScreen(
                          talentId: talent.id,
                          ownerId: talent.ownerId,
                          displayName: talent.displayName,
                          sports: sports,
                          skills: talent.skills,
                          achievements: talent.achievements,
                          goals: talent.goals,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('Achievements & Badges'),
                  ),
                ],
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_outlined),
              title: Text('Verification'),
              subtitle: Text('أي علامة تحقق رسمية يجب أن تعتمد على دليل أو جهة موثوقة؛ وجود الملف وحده لا يعني أنه حساب رسمي.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _talentScoreCard(TalentScoreBreakdown score) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined),
                const SizedBox(width: 8),
                const Expanded(child: Text('AUREN Talent Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                Text('${score.score}/100', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: score.score / 100),
            const SizedBox(height: 10),
            Text('Profile ${score.profile} • Skills ${score.skills} • Achievements ${score.achievements} • Evidence ${score.evidence} • Goals ${score.goals}'),
            const SizedBox(height: 8),
            const Text('هذا المؤشر يقيس قوة المعلومات والأدلة الموجودة في الملف، وليس مستوى اللاعب أو احتمالية نجاحه الرياضي.'),
          ],
        ),
      ),
    );
  }

  Widget _profileSummaryCard() {
    final values = <String, String>{
      'الرياضات': '${talent.sports.length}',
      'المهارات': '${talent.skills.length}',
      'الإنجازات': '${talent.achievements.length}',
      'الأهداف': '${talent.goals.length}',
    };
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Athlete Snapshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: values.entries.map((e) => Chip(avatar: const Icon(Icons.insights, size: 18), label: Text('${e.key}: ${e.value}'))).toList()),
    ])));
  }

  Widget _profileTrustCard() {
    final hasEvidence = talent.verificationEvidence.isNotEmpty;
    return Card(
      child: ListTile(
        leading: Icon(hasEvidence ? Icons.verified_outlined : Icons.info_outline),
        title: Text(hasEvidence ? 'Evidence available' : 'Profile status'),
        subtitle: Text(hasEvidence
            ? 'يوجد دليل مضاف للملف، لكنه لا يُعد توثيقاً رسمياً من AUREN.'
            : 'الملف غير موثق رسمياً. لا تعتمد على بيانات غير موثوقة كحقيقة.'),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(value)),
    );
  }

  Widget _section(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(value),
          ],
        ),
      ),
    );
  }

  Widget _chipsSection(String title, List<String> values) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: values.map((v) => Chip(label: Text(v))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
