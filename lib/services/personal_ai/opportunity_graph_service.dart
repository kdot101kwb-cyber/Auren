import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/goal.dart';
import '../../core/models/memory_item.dart';
import '../goals/goal_repository.dart';
import '../memory/memory_repository.dart';
import '../business/business_repository.dart';

class AurenOpportunityGraphNode {
  final String id, type, title, detail;
  final double score;
  const AurenOpportunityGraphNode({required this.id, required this.type, required this.title, required this.detail, required this.score});
}

class AurenOpportunityGraphService {
  final GoalRepository _goals;
  final MemoryRepository _memory;
  final BusinessRepository _business;
  final FirebaseFirestore _db;
  AurenOpportunityGraphService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        _goals = GoalRepository(firestore: firestore),
        _memory = MemoryRepository(firestore: firestore),
        _business = BusinessRepository(firestore: firestore);

  Future<List<AurenOpportunityGraphNode>> build(String uid) async {
    final goals = await _goals.watch(uid).first;
    final memories = await _memory.watch(uid).first;
    final businesses = await _business.watchPublic().first;
    final nodes = <AurenOpportunityGraphNode>[];
    final terms = <String>{};
    for (final g in goals.where((g) => g.status == 'active')) {
      nodes.add(AurenOpportunityGraphNode(id:'goal_${g.id}', type:'goal', title:g.title, detail:'تقدم ${g.progress}%', score:g.progress / 100));
      terms.addAll(_tokens(g.title));
      terms.addAll(_tokens(g.description ?? ''));
    }
    for (final m in memories.where((m) => m.enabled)) {
      nodes.add(AurenOpportunityGraphNode(id:'memory_${m.id}', type:'skill_or_context', title:m.key, detail:m.value, score:0.5));
      terms.addAll(_tokens(m.key));
      terms.addAll(_tokens(m.value));
    }
    for (final b in businesses.where((b) => b.ownerId == uid)) {
      nodes.add(AurenOpportunityGraphNode(id:'business_${b.id}', type:'business', title:b.name, detail:'${b.category} • ${b.city}', score:b.verified ? 1 : 0.7));
      terms.addAll(_tokens('${b.name} ${b.description} ${b.category} ${b.businessType} ${b.city} ${b.country}'));
    }
    final candidates = businesses.where((b) => b.ownerId != uid && b.visibility == 'public').map((b) {
      final text = '${b.name} ${b.description} ${b.category} ${b.businessType} ${b.city} ${b.country}'.toLowerCase();
      final hits = terms.where((t) => t.length > 2 && text.contains(t)).length;
      final score = hits == 0 ? 0.0 : (hits / terms.length.clamp(1, 100)).clamp(0.0, 1.0).toDouble();
      return AurenOpportunityGraphNode(id:'opportunity_${b.id}', type:'opportunity', title:b.name, detail:'${b.category} • ${b.city}', score:score);
    }).where((n) => n.score > 0).toList();
    candidates.sort((a,b) => b.score.compareTo(a.score));
    nodes.addAll(candidates.take(30));
    await _db.collection('users').doc(uid).collection('opportunity_graph').doc('current').set({
      'nodes': nodes.map((n) => {'id':n.id,'type':n.type,'title':n.title,'detail':n.detail,'score':n.score}).toList(),
      'generatedAt': FieldValue.serverTimestamp(),
    });
    return nodes;
  }

  Set<String> _tokens(String input) => input.toLowerCase().split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)).where((x) => x.length > 2).toSet();
  Stream<DocumentSnapshot<Map<String,dynamic>>> watch(String uid) => _db.collection('users').doc(uid).collection('opportunity_graph').doc('current').snapshots();
}