import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../core/models/search_result.dart';
import '../../../core/models/user_profile.dart';
import '../../../services/search/global_search_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../profile/presentation/public_profile_screen.dart';

class AurenGlobalSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const AurenGlobalSearchScreen({super.key, this.initialQuery});
  @override State<AurenGlobalSearchScreen> createState() => _AurenGlobalSearchScreenState();
}

class _AurenGlobalSearchScreenState extends State<AurenGlobalSearchScreen> {
  final _controller = TextEditingController();
  final _repository = AurenGlobalSearchRepository();
  List<AurenSearchResult> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _controller.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) { setState(() { _results = []; _lastQuery = ''; }); return; }
    setState(() => _loading = true);
    try {
      final results = await _repository.search(query, uid: FirebaseAurenAuthService().currentUserId);
      if (!mounted) return;
      setState(() { _results = results; _lastQuery = query; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  String _label(AurenSearchType type) => switch (type) {
    AurenSearchType.people => 'People',
    AurenSearchType.posts => 'Pulse',
    AurenSearchType.businesses => 'Businesses',
    AurenSearchType.products => 'Products',
    AurenSearchType.entertainment => 'Entertainment',
    AurenSearchType.places => 'Places',
    AurenSearchType.opportunities => 'Opportunities',
    AurenSearchType.ai => 'AUREN AI',
  };

  IconData _icon(AurenSearchType type) => switch (type) {
    AurenSearchType.people => Icons.person_outline,
    AurenSearchType.posts => Icons.dynamic_feed_outlined,
    AurenSearchType.businesses => Icons.storefront_outlined,
    AurenSearchType.products => Icons.shopping_bag_outlined,
    AurenSearchType.entertainment => Icons.movie_outlined,
    AurenSearchType.places => Icons.place_outlined,
    AurenSearchType.opportunities => Icons.work_outline,
    AurenSearchType.ai => Icons.auto_awesome,
  };

  void _openResult(AurenSearchResult result) {
    if (result.type == AurenSearchType.people) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AurenPublicProfileScreen(profile: AurenUserProfile(uid: result.id, displayName: result.title, photoUrl: result.imageUrl, createdAt: DateTime.now()))));
      return;
    }

    final prompts = <AurenSearchType, String>{
      AurenSearchType.posts: 'افتح وفسّر لي Pulse: ${result.title}',
      AurenSearchType.businesses: 'ساعدني أتعرف على Business: ${result.title}. ${result.subtitle}',
      AurenSearchType.products: 'ساعدني أتعرف على المنتج: ${result.title}. ${result.subtitle}',
      AurenSearchType.entertainment: 'ساعدني أستكشف المحتوى الترفيهي: ${result.title}. ${result.subtitle}',
      AurenSearchType.places: 'ساعدني أستكشف المكان: ${result.title}. ${result.subtitle}',
      AurenSearchType.opportunities: 'ساعدني أقيّم فرصة: ${result.title}. ${result.subtitle}',
      AurenSearchType.ai: _lastQuery,
    };

    Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompts[result.type] ?? _lastQuery)));
  }

  @override Widget build(BuildContext context) {
    final grouped = <AurenSearchType, List<AurenSearchResult>>{};
    for (final r in _results) { grouped.putIfAbsent(r.type, () => []).add(r); }
    return Scaffold(
      appBar: AppBar(
        title: TextField(controller: _controller, autofocus: true, textInputAction: TextInputAction.search, onSubmitted: (_) => _search(), decoration: const InputDecoration(hintText: 'Search AUREN…', border: InputBorder.none)),
        actions: [IconButton(onPressed: _loading ? null : _search, icon: const Icon(Icons.search))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _results.isEmpty ? _EmptySearch(query: _lastQuery) : ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          for (final entry in grouped.entries) ...[
            Padding(padding: const EdgeInsets.fromLTRB(8, 12, 8, 4), child: Text(_label(entry.key), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ...entry.value.map((r) => Card(child: ListTile(leading: r.imageUrl == null ? Icon(_icon(r.type)) : CircleAvatar(backgroundImage: NetworkImage(r.imageUrl!)), title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text(r.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right), onTap: () => _openResult(r)))),
          ],
          Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Ask AUREN AI'), subtitle: Text('ابحث بذكاء عن: $_lastQuery'), trailing: const Icon(Icons.chevron_right), onTap: () => _openResult(const AurenSearchResult(id: 'ai', type: AurenSearchType.ai, title: 'AUREN AI Search', subtitle: 'Ask AUREN')))),
        ],
      ),
    );
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
}

class _EmptySearch extends StatelessWidget {
  final String query;
  const _EmptySearch({required this.query});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.search_off, size: 48), const SizedBox(height: 12), Text(query.isEmpty ? 'ابحث عن People, Posts, Businesses, Places أو Opportunities' : 'ما لقينا نتائج مباشرة لـ "$query"', textAlign: TextAlign.center), if (query.isNotEmpty) ...[const SizedBox(height: 16), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: query))), icon: const Icon(Icons.auto_awesome), label: const Text('اسأل AUREN AI'))]])));
}
