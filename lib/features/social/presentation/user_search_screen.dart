import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../../../services/users/user_search_repository.dart';
import '../../profile/presentation/public_profile_screen.dart';

class AurenUserSearchScreen extends StatefulWidget {
  const AurenUserSearchScreen({super.key});

  @override
  State<AurenUserSearchScreen> createState() => _AurenUserSearchScreenState();
}

class _AurenUserSearchScreenState extends State<AurenUserSearchScreen> {
  final c = TextEditingController();
  List<AurenUserProfile> results = [];
  bool loading = false;

  Future<void> search() async {
    final query = c.text.trim();
    if (query.isEmpty) {
      setState(() => results = []);
      return;
    }
    setState(() => loading = true);
    try {
      results = await UserSearchRepository().search(query);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: TextField(
        controller: c,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => search(),
        decoration: const InputDecoration(hintText: 'Search people…', border: InputBorder.none),
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, i) {
              final p = results[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(p.displayName),
                subtitle: Text(p.uid),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AurenPublicProfileScreen(profile: p)),
                ),
              );
            },
          ),
  );

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }
}