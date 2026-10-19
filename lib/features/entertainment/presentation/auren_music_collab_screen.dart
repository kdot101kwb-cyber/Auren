import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';

/// First collaboration-planning step for AUREN Music.
///
/// This screen creates a collaboration brief with AI. It does not create a
/// persisted project, send invitations, publish audio, or assign legal rights.
class AurenMusicCollabScreen extends StatefulWidget {
  const AurenMusicCollabScreen({super.key});

  @override
  State<AurenMusicCollabScreen> createState() => _AurenMusicCollabScreenState();
}

class _AurenMusicCollabScreenState extends State<AurenMusicCollabScreen> {
  final _ideaController = TextEditingController();
  final Set<String> _roles = {'Vocalist / Rapper', 'Producer / Beatmaker'};
  String _mode = 'Global Collab';
  String _genre = 'Hip Hop';
  String _language = 'Arabic';
  bool _includeOpenVerse = false;

  static const _modes = ['Global Collab', 'Open Verse'];
  static const _genres = [
    'Hip Hop',
    'Afrobeat',
    'Sudanese fusion',
    'R&B',
    'Pop',
    'Electronic',
    'Other',
  ];
  static const _languages = ['Arabic', 'English', 'Both / multilingual'];
  static const _availableRoles = [
    'Vocalist / Rapper',
    'Producer / Beatmaker',
    'Songwriter',
    'Instrumentalist',
    'Mixing engineer',
    'Visual artist',
  ];

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  void _createBrief() {
    final idea = _ideaController.text.trim();
    if (idea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب فكرة المشروع أولاً.')),
      );
      return;
    }

    final roles = _roles.isEmpty ? 'Suggest suitable collaborators' : _roles.join(', ');
    final prompt = '''
Act as the AUREN Music collaboration planner.
Create a practical, original music collaboration brief using these user choices:
Project mode: $_mode
Idea: $idea
Genre / direction: $_genre
Language(s): $_language
Wanted collaborators: $roles
Open Verse requested: $_includeOpenVerse

Return:
1. A concise project title and creative concept.
2. A track structure and proposed contribution for each role.
3. A short collaborator call-out that does not invent people or claim that invitations were sent.
4. A low-budget workflow suitable for Android phones and unreliable internet.
5. A checklist for confirming ownership, sample/beat licenses, contributor credits,
   permission to remix, and revenue splits in writing before public or commercial release.
6. Next actions the user can do without paid services.

Use original creative material. Do not imitate a real artist's voice or claim copyrighted
beats are free to use. Be clear that this is a planning brief, not a saved project,
sent invitation, audio upload, rights agreement, or completed collaboration.
''';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Music Collab')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [colors.primaryContainer, colors.tertiaryContainer],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.public_rounded, size: 38),
                SizedBox(height: 8),
                Text(
                  'Make music together.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'خطّط لأغنية تجمع فنانين من أماكن مختلفة، أو افتح مقطعك لمساهمات جديدة.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('نوع المشروع', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _modes
                .map(
                  (mode) => ChoiceChip(
                    label: Text(mode),
                    selected: _mode == mode,
                    onSelected: (_) => setState(() => _mode = mode),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ideaController,
            minLines: 3,
            maxLines: 5,
            maxLength: 600,
            decoration: const InputDecoration(
              labelText: 'فكرة الأغنية أو المقطع',
              hintText: 'مثلاً: راب عن الأمل يجمع إيقاعاً سودانياً مع Afrobeat...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          const Text('النوع الموسيقي', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _genre,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _genres
                .map((genre) => DropdownMenuItem(value: genre, child: Text(genre)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _genre = value);
            },
          ),
          const SizedBox(height: 14),
          const Text('لغة العمل', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _language,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _languages
                .map((language) => DropdownMenuItem(value: language, child: Text(language)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _language = value);
            },
          ),
          const SizedBox(height: 16),
          const Text('المتعاونون المطلوبون', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ..._availableRoles.map(
            (role) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _roles.contains(role),
              title: Text(role),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _roles.add(role);
                } else {
                  _roles.remove(role);
                }
              }),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _includeOpenVerse,
            title: const Text('ضمّن فكرة Open Verse'),
            subtitle: const Text('اقترح طريقة لفتح جزء من المقطع لمساهمات الآخرين.'),
            onChanged: (value) => setState(() => _includeOpenVerse = value),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _createBrief,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('أنشئ خطة التعاون مع AUREN AI'),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'المرحلة الحالية تنشئ خطة إبداعية بمساعدة AI فقط. لا تحفظ مشروعاً على الخادم ولا ترسل دعوات أو ترفع صوتاً أو تسجل حقوقاً. هذه الوظائف تحتاج إلى تخزين وصلاحيات واختبارات مستقلة.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
