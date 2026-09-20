import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/agent_listing.dart';
import '../../../services/agents/agent_review_repository.dart';

class AgentReviewsSheet extends StatefulWidget {
  final AurenAgentListing agent;
  const AgentReviewsSheet({super.key, required this.agent});
  @override State<AgentReviewsSheet> createState() => _AgentReviewsSheetState();
}

class _AgentReviewsSheetState extends State<AgentReviewsSheet> {
  int _rating = 5;
  final _text = TextEditingController();
  bool _submitting = false;

  @override void dispose() { _text.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final text = _text.text.trim();
    if (text.isEmpty || text.length > 1000) return;
    setState(() => _submitting = true);
    try {
      await AurenAgentReviewRepository().submit(agentId: widget.agent.agentId, rating: _rating, text: text);
      _text.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التقييم.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال التقييم: $e')));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override Widget build(BuildContext context) => SafeArea(
    child: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: Text('Reviews • ${widget.agent.name}', style: Theme.of(context).textTheme.titleLarge)),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
      ])),
      Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(
        padding: const EdgeInsets.all(12), child: Column(children: [
          const Align(alignment: Alignment.centerLeft, child: Text('قيّم الـAgent')),
          Row(children: List.generate(5, (i) => IconButton(
            onPressed: _submitting ? null : () => setState(() => _rating = i + 1),
            icon: Icon(i < _rating ? Icons.star : Icons.star_border),
          ))),
          TextField(controller: _text, minLines: 2, maxLines: 4, maxLength: 1000,
            decoration: const InputDecoration(hintText: 'اكتب تجربتك...', border: OutlineInputBorder())),
          Align(alignment: Alignment.centerRight, child: FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'جاري الإرسال...' : 'إرسال التقييم'),
          )),
        ]),
      )),
      const SizedBox(height: 8),
      Expanded(child: StreamBuilder<List<AurenAgentReview>>(
        stream: AurenAgentReviewRepository().watch(widget.agent.agentId),
        builder: (context, snapshot) {
          final reviews = snapshot.data ?? const <AurenAgentReview>[];
          return reviews.isEmpty ? const Center(child: Text('لا توجد مراجعات بعد.')) :
            ListView.separated(itemCount: reviews.length, padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(child: Text(reviews[i].rating.toString())),
                title: Text(reviews[i].text),
                subtitle: Text('تقييم ${reviews[i].rating}/5'),
              ));
        },
      )),
    ]),
  );
}
