import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auren_interactive_story.dart';

class AurenInteractiveStoryScreen extends StatefulWidget {
  const AurenInteractiveStoryScreen({super.key});

  @override
  State<AurenInteractiveStoryScreen> createState() =>
      _AurenInteractiveStoryScreenState();
}

class _AurenInteractiveStoryScreenState
    extends State<AurenInteractiveStoryScreen> {
  static const _nodeKey = 'auren.interactive_story.node.v1';
  static const _historyKey = 'auren.interactive_story.history.v1';

  String _nodeId = AurenInteractiveStory.startNodeId;
  final List<String> _history = [];
  bool _isLoading = true;

  AurenStoryNode get _node => AurenInteractiveStory.node(_nodeId);

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedNodeId = preferences.getString(_nodeKey);
      final savedHistory = preferences.getString(_historyKey);
      if (savedNodeId != null &&
          AurenInteractiveStory.nodes.containsKey(savedNodeId)) {
        final decoded = savedHistory == null
            ? <dynamic>[]
            : jsonDecode(savedHistory) as List<dynamic>;
        final restoredHistory = decoded
            .whereType<String>()
            .where(AurenInteractiveStory.nodes.containsKey)
            .toList();
        if (mounted) {
          setState(() {
            _nodeId = savedNodeId;
            _history
              ..clear()
              ..addAll(restoredHistory);
          });
        }
      }
    } on Object {
      // Invalid or unavailable local state should never block starting a story.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProgress() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_nodeKey, _nodeId);
      await preferences.setString(_historyKey, jsonEncode(_history));
    } on Object {
      // Story play remains available if local persistence is unavailable.
    }
  }

  void _choose(AurenStoryChoice choice) {
    setState(() {
      _history.add(_nodeId);
      _nodeId = choice.nextNodeId;
    });
    _saveProgress();
  }

  void _back() {
    if (_history.isEmpty) return;
    setState(() => _nodeId = _history.removeLast());
    _saveProgress();
  }

  void _restart() {
    setState(() {
      _nodeId = AurenInteractiveStory.startNodeId;
      _history.clear();
    });
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AUREN • عالم موازٍ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                subtitle: Text(
                  'يمكنك العودة لتغيير قرارك أو إعادة القصة من البداية.',
                ),
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
                    title: Text(
                      choice.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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
              'يُحفظ تقدمك على هذا الجهاز فقط. لا تُرسل اختياراتك إلى خادم.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
