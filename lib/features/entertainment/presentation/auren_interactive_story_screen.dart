import 'package:flutter/material.dart';

import '../domain/auren_interactive_story.dart';

class AurenInteractiveStoryScreen extends StatefulWidget {
  const AurenInteractiveStoryScreen({super.key});

  @override
  State<AurenInteractiveStoryScreen> createState() =>
      _AurenInteractiveStoryScreenState();
}

class _AurenInteractiveStoryScreenState
    extends State<AurenInteractiveStoryScreen> {
  String _nodeId = AurenInteractiveStory.startNodeId;
  final List<String> _history = [];

  AurenStoryNode get _node => AurenInteractiveStory.node(_nodeId);

  void _choose(AurenStoryChoice choice) {
    setState(() {
      _history.add(_nodeId);
      _nodeId = choice.nextNodeId;
    });
  }

  void _back() {
    if (_history.isEmpty) return;
    setState(() => _nodeId = _history.removeLast());
  }

  void _restart() {
    setState(() {
      _nodeId = AurenInteractiveStory.startNodeId;
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final node = _node;
    final isEnding = node.ending != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN • عالم موازٍ'),
        actions: [
          IconButton(
            tooltip: 'إعادة القصة',
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF222B55), Color(0xFF6B3FA0)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  const SizedBox(height: 18),
                  Text(
                    node.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    node.narration,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: .92),
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isEnding) ...[
              const ListTile(
                leading: Icon(Icons.emoji_events_outlined),
                title: Text('وصلت إلى نهاية هذا المسار'),
                subtitle: Text('يمكنك العودة لتغيير قرارك أو إعادة القصة من البداية.'),
              ),
              FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay),
                label: const Text('جرّب مسارًا آخر'),
              ),
            ] else ...[
              Text(
                'اختيارك التالي',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              for (final choice in node.choices)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(choice.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(choice.description),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _choose(choice),
                  ),
                ),
            ],
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.undo),
                label: const Text('ارجع خطوة'),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'تجربة قصصية محلية: اختياراتك تغيّر المسار، ولا تُرسل بياناتك إلى خادم.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
