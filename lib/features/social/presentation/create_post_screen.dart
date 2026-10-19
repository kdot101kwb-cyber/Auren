import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../core/theme/auren_nebula_tokens.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/post_repository.dart';

class AurenCreatePostScreen extends StatefulWidget {
  const AurenCreatePostScreen({super.key});
  @override
  State<AurenCreatePostScreen> createState() => _AurenCreatePostScreenState();
}

class _AurenCreatePostScreenState extends State<AurenCreatePostScreen> {
  final textController = TextEditingController();
  final mediaController = TextEditingController();
  bool saving = false;
  bool showMedia = false;
  String contentType = 'moment';

  static const types = <(String, String, IconData)>[
    ('moment', 'Post', Icons.notes_rounded),
    ('idea', 'Idea', Icons.lightbulb_outline_rounded),
    ('question', 'Question', Icons.help_outline_rounded),
    ('project', 'Project', Icons.rocket_launch_outlined),
    ('opportunity', 'Opportunity', Icons.handshake_outlined),
  ];

  Future<void> save() async {
    final text = textController.text.trim();
    final mediaUrl = mediaController.text.trim();
    final uid = FirebaseAurenAuthService().currentUserId;
    if (saving) return;
    if (text.isEmpty && mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write something or add a media link first.')));
      return;
    }
    if (mediaUrl.isNotEmpty && !mediaUrl.startsWith('https://') && !mediaUrl.startsWith('http://')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid link starting with https://')));
      return;
    }
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to publish a post.')));
      return;
    }
    setState(() => saving = true);
    try {
      await PostRepository().create(AurenPost(
        id: 'post_${DateTime.now().microsecondsSinceEpoch}', authorId: uid, text: text,
        mediaUrl: mediaUrl, mediaType: mediaUrl.isEmpty ? 'none' : 'image',
        contentType: contentType,
        contextLabel: contentType == 'opportunity' ? 'Open for collaboration' : contentType == 'project' ? 'Building now' : 'Shared with AUREN',
        actionLabel: contentType == 'opportunity' ? 'Connect' : contentType == 'project' ? 'Join' : contentType == 'question' ? 'Answer' : contentType == 'idea' ? 'Build' : '',
        createdAt: DateTime.now(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your post is live in AUREN Pulse.')));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not publish your post. Please try again.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final surface = dark ? AurenNebulaTokens.surface : Colors.white;
    final outline = dark ? AurenNebulaTokens.outline : const Color(0xFFE2E5EF);
    return Scaffold(
      backgroundColor: dark ? AurenNebulaTokens.midnight : AurenNebulaTokens.lightCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0,
        leading: IconButton(tooltip: 'Close', onPressed: saving ? null : () => Navigator.maybePop(context), icon: const Icon(Icons.close_rounded)),
        title: const Text('Create a post', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: FilledButton(
            onPressed: saving ? null : save,
            style: FilledButton.styleFrom(backgroundColor: AurenNebulaTokens.violet, foregroundColor: const Color(0xFF101020), shape: const StadiumBorder()),
            child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Row(mainAxisSize: MainAxisSize.min, children: [Text('Publish', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(width: 5), Icon(Icons.arrow_upward_rounded, size: 17)]),
          ),
        )],
      ),
      body: SafeArea(top: false, child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: dark ? const [Color(0xFF242044), Color(0xFF111827)] : const [Color(0xFFECEBFF), Color(0xFFF2FAFF)]),
              borderRadius: BorderRadius.circular(25), border: Border.all(color: outline),
            ),
            child: const Row(children: [
              DecoratedBox(decoration: BoxDecoration(gradient: AurenNebulaTokens.signatureGradient, borderRadius: BorderRadius.all(Radius.circular(15))), child: SizedBox(width: 48, height: 48, child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF101020), size: 25))),
              SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your world. Your voice.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 4), Text('Share a thought, start a conversation, or bring an idea to life.', style: TextStyle(fontSize: 13, height: 1.35)),
              ])),
            ]),
          ),
          const SizedBox(height: 22),
          Text('WHAT ARE WE SHARING?', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w900, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          SizedBox(height: 88, child: ListView.separated(
            scrollDirection: Axis.horizontal, itemCount: types.length, separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final item = types[index]; final active = contentType == item.$1;
              return InkWell(
                borderRadius: BorderRadius.circular(18), onTap: () => setState(() => contentType = item.$1),
                child: AnimatedContainer(
                  duration: AurenNebulaTokens.quickMotion, width: 104,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: active ? AurenNebulaTokens.violet.withValues(alpha: dark ? .2 : .12) : surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: active ? AurenNebulaTokens.violet : outline, width: active ? 1.6 : 1)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(item.$3, size: 22, color: active ? AurenNebulaTokens.violet : scheme.onSurfaceVariant),
                    const SizedBox(height: 6), Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w900 : FontWeight.w600)),
                  ]),
                ),
              );
            },
          )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: outline), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .1 : .035), blurRadius: 22, offset: const Offset(0, 8))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: AurenNebulaTokens.violet.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.person_rounded, color: AurenNebulaTokens.violet)),
                const SizedBox(width: 11),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your AUREN space', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 2), Text('Ready to share with your community', style: TextStyle(fontSize: 12))])),
                Icon(Icons.public_rounded, color: scheme.onSurfaceVariant, size: 20),
              ]),
              const SizedBox(height: 14),
              TextField(controller: textController, minLines: 5, maxLines: 8, maxLength: 2200, textCapitalization: TextCapitalization.sentences, keyboardType: TextInputType.multiline, decoration: const InputDecoration(hintText: 'What’s on your mind?\n\nA good idea can start right here…', border: InputBorder.none, counterText: '', contentPadding: EdgeInsets.zero), style: const TextStyle(fontSize: 17, height: 1.5)),
              const Divider(height: 20),
              Row(children: [
                const Icon(Icons.auto_awesome_rounded, size: 17, color: AurenNebulaTokens.violet), const SizedBox(width: 7),
                Expanded(child: Text('Make it worth sharing.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
                ValueListenableBuilder<TextEditingValue>(valueListenable: textController, builder: (context, value, _) => Text('${value.text.length}/2200', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant))),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: outline)),
            child: Column(children: [
              ListTile(
                leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AurenNebulaTokens.electricBlue.withValues(alpha: .13), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.link_rounded, color: AurenNebulaTokens.electricBlue)),
                title: const Text('Add a media link', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Optional · Paste an image URL'),
                trailing: Icon(showMedia ? Icons.keyboard_arrow_up_rounded : Icons.add_rounded), onTap: () => setState(() => showMedia = !showMedia),
              ),
              if (showMedia) Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: TextField(controller: mediaController, keyboardType: TextInputType.url, textCapitalization: TextCapitalization.none, decoration: InputDecoration(hintText: 'https://example.com/image.jpg', prefixIcon: const Icon(Icons.insert_link_rounded), filled: true, fillColor: dark ? AurenNebulaTokens.midnight : AurenNebulaTokens.lightCanvas, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: outline)))),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Text('Tip: clear, specific posts make it easier for people to respond.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      )),
    );
  }

  @override
  void dispose() { textController.dispose(); mediaController.dispose(); super.dispose(); }
}
