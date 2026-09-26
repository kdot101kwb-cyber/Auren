import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/post.dart';
import '../../../core/models/user_profile.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/post_repository.dart';
import '../../../services/social/safety_repository.dart';
import 'comments_screen.dart';
import 'create_post_screen.dart';
import 'edit_post_screen.dart';
import 'saved_pulse_screen.dart';
import 'user_search_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../../services/core/auren_core_five_repository.dart';

class AurenTimelineScreen extends StatefulWidget {
  const AurenTimelineScreen({super.key});

  @override
  State<AurenTimelineScreen> createState() => _AurenTimelineScreenState();
}

class _AurenTimelineScreenState extends State<AurenTimelineScreen> {
  String selectedType = 'all';

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAurenAuthService();
    final uid = auth.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Pulse'),
        actions: [
          IconButton(
            tooltip: 'Find people',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenUserSearchScreen())),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Saved Pulse',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSavedPulseScreen())),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          IconButton(
            tooltip: 'Core 5 AI',
            onPressed: () async {
              if (uid == null) return;
              final snapshot = await AurenCoreFiveRepository().load(uid);
              if (!context.mounted) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: snapshot.toPrompt())));
            },
            icon: const Icon(Icons.hub_outlined),
          ),
          IconButton(
            tooltip: 'Create',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AurenCreatePostScreen()),
            ),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AurenCreatePostScreen()),
        ),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Create'),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in required'))
          : StreamBuilder<Set<String>>(
              stream: AurenSafetyRepository().watchBlockedIds(uid),
              builder: (context, blockedSnapshot) {
                final blockedIds = blockedSnapshot.data ?? const <String>{};
                return StreamBuilder<List<AurenPost>>(
              stream: PostRepository().watchFeed(blockedAuthorIds: blockedIds),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load AUREN Pulse: ${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allPosts = snapshot.data!;
                final posts = selectedType == 'all'
                    ? allPosts
                    : allPosts.where((p) => p.contentType == selectedType).toList();
                final opportunities = allPosts.where((p) => p.contentType == 'opportunity').length;
                final projects = allPosts.where((p) => p.contentType == 'project').length;
                final types = const [('all', 'All'), ('moment', 'Moments'), ('idea', 'Ideas'), ('question', 'Questions'), ('project', 'Projects'), ('opportunity', 'Opportunities')];
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
                  itemCount: posts.length + 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) return _PulseCoreFiveCard(uid: uid);
                    if (i == 1) return const _MomentsStrip();
                    if (i == 2) return _PulseFilterBar(types: types, selected: selectedType, onChanged: (value) => setState(() => selectedType = value));
                    if (i == 3) return _PulseSignals(opportunities: opportunities, projects: projects);
                    if (posts.isEmpty) return const _EmptyPulse();
                    return _PulseCard(post: posts[i - 4], uid: uid);
                  },
                );
              },
                );
              },
            ),
    );
  }
}

class _NextMoveCard extends StatelessWidget {
  const _NextMoveCard();

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                child: Icon(Icons.auto_awesome),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your next move',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('People, ideas and opportunities selected for your goals.'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ask AUREN',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MessengerScreen(
                      initialPrompt: 'حلّل ما يحدث في AUREN Pulse الآن، واربط الأفكار والمشاريع والفرص بما يمكنني فعله كخطوة تالية.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome),
              ),
              IconButton(
                tooltip: 'See why',
                onPressed: () => _showWhy(context),
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
        ),
      );

  static void _showWhy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'AUREN Pulse can personalize what you see using your interests, follows, activity, goals and nearby context.',
        ),
      ),
    );
  }
}

class _MomentsStrip extends StatelessWidget {
  const _MomentsStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Create', Icons.add),
      ('Now', Icons.bolt),
      ('Nearby', Icons.location_on_outlined),
      ('Projects', Icons.rocket_launch_outlined),
      ('People', Icons.people_outline),
    ];
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openMoment(context, items[i].$1),
          child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[i].$2, size: 24),
              const SizedBox(height: 6),
              Text(items[i].$1, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  static void _openMoment(BuildContext context, String item) {
    switch (item) {
      case 'Create':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenCreatePostScreen()));
        break;
      case 'People':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenUserSearchScreen()));
        break;
      case 'Nearby':
      case 'Now':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenDiscoverScreen()));
        break;
      case 'Projects':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'أرني المشاريع والفرص التي يمكنني المساعدة فيها.')));
        break;
    }
  }
}

class _PulseFilterBar extends StatelessWidget {
  final List<(String, String)> types;
  final String selected;
  final ValueChanged<String> onChanged;
  const _PulseFilterBar({required this.types, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: types.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(type.$2), selected: selected == type.$1, onSelected: (_) => onChanged(type.$1)),
          )).toList(),
        ),
      );
}

class _PulseSignals extends StatelessWidget { final int opportunities; final int projects; const _PulseSignals({required this.opportunities, required this.projects}); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Expanded(child: _Signal(icon: Icons.work_outline, value: opportunities, label: 'Opportunities')), Expanded(child: _Signal(icon: Icons.rocket_launch_outlined, value: projects, label: 'Projects')), Expanded(child: _Signal(icon: Icons.auto_awesome, value: opportunities + projects, label: 'Signals'))]))); }

class _Signal extends StatelessWidget { final IconData icon; final int value; final String label; const _Signal({required this.icon, required this.value, required this.label}); @override Widget build(BuildContext context) => Column(children: [Icon(icon, size: 20), const SizedBox(height: 4), Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)), Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)]); }

class _PulseCard extends StatelessWidget {
  final AurenPost post;
  final String uid;

  const _PulseCard({required this.post, required this.uid});

  String get typeLabel {
    switch (post.contentType) {
      case 'opportunity':
        return 'Opportunity';
      case 'project':
        return 'Project';
      case 'question':
        return 'Question';
      case 'idea':
        return 'Idea';
      default:
        return 'Moment';
    }
  }

  IconData get typeIcon {
    switch (post.contentType) {
      case 'opportunity':
        return Icons.work_outline;
      case 'project':
        return Icons.rocket_launch_outlined;
      case 'question':
        return Icons.help_outline;
      case 'idea':
        return Icons.lightbulb_outline;
      default:
        return Icons.bolt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = PostRepository();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 6),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person_outline, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (post.contextLabel.isNotEmpty)
                        Text(post.contextLabel,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(typeIcon, size: 16),
                  label: Text(typeLabel),
                  visualDensity: VisualDensity.compact,
                ),
                PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _openEdit(context);
                      if (value == 'delete') _confirmDelete(context, repo);
                      if (value == 'report') _reportPost(context, repo);
                    },
                    itemBuilder: (_) => [
                      if (post.authorId == uid) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit post'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete post'),
                        ),
                      ],
                      if (post.authorId != uid)
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('Report post'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (post.mediaUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Colors.black26,
                  child: Center(child: Icon(Icons.broken_image_outlined, size: 42)),
                ),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator()),
              ),
            ),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(post.text),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
            child: Row(
              children: [
                StreamBuilder<String?>(
                  stream: repo.watchReaction(post.id, uid),
                  builder: (context, s) {
                    final reaction = s.data;
                    return IconButton(
                      tooltip: 'React',
                      onPressed: () => _showReactionPicker(context, repo, reaction),
                      icon: Icon(reaction == null ? Icons.emoji_emotions_outlined : _reactionIcon(reaction)),
                    );
                  },
                ),
                
                IconButton(
                  tooltip: 'Discuss',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AurenCommentsScreen(postId: post.id),
                    ),
                  ),
                  icon: const Icon(Icons.forum_outlined),
                ),
                StreamBuilder<bool>(
                  stream: repo.watchSaved(post.id, uid),
                  builder: (context, s) {
                    final saved = s.data ?? false;
                    return IconButton(
                      tooltip: saved ? 'Saved' : 'Save',
                      onPressed: () => repo.toggleSaved(post.id, uid, saved),
                      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Share',
                  onPressed: () => _sharePost(context),
                  icon: const Icon(Icons.ios_share_outlined),
                ),
                const Spacer(),
                if (post.actionLabel.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => _openAuthor(context),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(post.actionLabel),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              '${post.likes} reactions • ${post.comments} discussions',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (post.contentType == 'project' || post.contentType == 'opportunity')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('AUREN can match people with the right skills for this.')),
                  OutlinedButton(onPressed: () => _openMatch(context), child: const Text('Match')),
                ],
              ),
            ),
        ],
      ),
    );
  }
  void _openEdit(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AurenEditPostScreen(post: post)));
  }

  void _showEditHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit is coming next. Your original post remains unchanged.'),
      ),
    );
  }
  Future<void> _reportPost(BuildContext context, PostRepository repo) async {
    final reasons = ['Spam', 'Harassment', 'Scam or fraud', 'Unsafe content', 'Other'];
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Report post'),
        children: reasons.map((r) => SimpleDialogOption(onPressed: () => Navigator.pop(context, r), child: Text(r))).toList(),
      ),
    );
    if (reason == null) return;
    await repo.report(post.id, uid, reason);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted.')));
  }
  Future<void> _confirmDelete(BuildContext context, PostRepository repo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repo.delete(post.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted.')),
      );
    }
  }
  void _showReactionPicker(BuildContext context, PostRepository repo, String? current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final item in const [('like','👍'),('love','❤️'),('fire','🔥'),('support','🙌'),('idea','💡'),('wow','✨')])
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  repo.setReaction(post.id, uid, item.$1);
                },
                icon: Text(item.$2, style: const TextStyle(fontSize: 28)),
              ),
            if (current != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  repo.setReaction(post.id, uid, null);
                },
                child: const Text('Remove'),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _reactionIcon(String reaction) {
    switch (reaction) {
      case 'love': return Icons.favorite;
      case 'fire': return Icons.local_fire_department;
      case 'support': return Icons.volunteer_activism;
      case 'idea': return Icons.lightbulb;
      case 'wow': return Icons.auto_awesome;
      default: return Icons.thumb_up;
    }
  }

  void _openAuthor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AurenPublicProfileScreen(
          profile: AurenUserProfile(
            uid: post.authorId,
            displayName: post.authorId,
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  void _openMatch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AurenUserSearchScreen()),
    );
  }

  void _sharePost(BuildContext context) {
    Clipboard.setData(ClipboardData(text: 'https://auren.app/pulse/${post.id}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AUREN Pulse link copied.')),
    );
  }

}

class _PulseCoreFiveCard extends StatelessWidget {
  final String uid;
  const _PulseCoreFiveCard({required this.uid});

  @override
  Widget build(BuildContext context) => FutureBuilder<AurenCoreFiveSnapshot>(
    future: AurenCoreFiveRepository().load(uid),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const _NextMoveCard();
      final core = snapshot.data!;
      return Card(
        child: ListTile(
          leading: const Icon(Icons.hub_outlined),
          title: const Text('Pulse مرتبط بحياتك'),
          subtitle: Text(core.nextMove),
          trailing: const Icon(Icons.auto_awesome),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MessengerScreen(initialPrompt: core.toPrompt()),
            ),
          ),
        ),
      );
    },
  );
}

class _EmptyPulse extends StatelessWidget {
  const _EmptyPulse();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.auto_awesome, size: 44),
              const SizedBox(height: 10),
              const Text('Your Pulse starts here',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Create an idea, project, question or opportunity.'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AurenCreatePostScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create your first'),
              ),
            ],
          ),
        ),
      );
}