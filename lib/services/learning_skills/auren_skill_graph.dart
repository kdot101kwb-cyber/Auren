import '../talent/talent_skill_matcher.dart';

class AurenSkillNode {
  const AurenSkillNode({required this.id, required this.name, this.prerequisites = const []});
  final String id;
  final String name;
  final List<String> prerequisites;
}

class AurenSkillGraph {
  AurenSkillGraph(Iterable<AurenSkillNode> nodes) : nodes = List.unmodifiable(nodes) {
    final ids = <String>{};
    for (final node in this.nodes) {
      if (node.id.trim().isEmpty || node.name.trim().isEmpty || !ids.add(node.id)) {
        throw ArgumentError('Skill graph requires unique non-empty IDs and names');
      }
    }
    for (final node in this.nodes) {
      if (node.prerequisites.any((id) => !ids.contains(id) || id == node.id)) {
        throw ArgumentError('Skill prerequisites must reference another known skill');
      }
    }
    if (_hasCycle()) throw ArgumentError('Skill graph must not contain cycles');
  }

  final List<AurenSkillNode> nodes;

  List<AurenSkillNode> prerequisitesFor(String skillId) {
    final node = _byId(skillId);
    return node.prerequisites.map(_byId).toList(growable: false);
  }

  List<AurenSkillNode> recommendNext(Iterable<String> acquiredSkillIds) {
    final acquired = acquiredSkillIds.toSet();
    return nodes.where((node) => !acquired.contains(node.id) &&
      node.prerequisites.every(acquired.contains)).toList(growable: false);
  }

  int readinessPercent(Iterable<String> acquiredSkillIds, String targetSkillId) {
    final acquired = acquiredSkillIds.toSet();
    final target = _byId(targetSkillId);
    final required = <String>{};
    void visit(AurenSkillNode node) {
      for (final id in node.prerequisites) {
        if (required.add(id)) visit(_byId(id));
      }
    }
    visit(target);
    if (required.isEmpty) return acquired.contains(target.id) ? 100 : 0;
    final completed = required.where(acquired.contains).length;
    return ((completed / required.length) * 100).round();
  }

  TalentSkillEvaluation evaluateSkills({required Iterable<String> acquiredNames, required Iterable<String> requiredNames}) =>
      TalentSkillMatcher.evaluate(verifiedSkills: acquiredNames, requiredSkills: requiredNames);

  AurenSkillNode _byId(String id) => nodes.firstWhere((node) => node.id == id, orElse: () => throw ArgumentError('Unknown skill: $id'));

  bool _hasCycle() {
    final visiting = <String>{}, visited = <String>{};
    final map = {for (final node in nodes) node.id: node};
    bool visit(String id) {
      if (visiting.contains(id)) return true;
      if (visited.contains(id)) return false;
      visiting.add(id);
      for (final dependency in map[id]!.prerequisites) {
        if (visit(dependency)) return true;
      }
      visiting.remove(id);
      visited.add(id);
      return false;
    }
    return nodes.any((node) => visit(node.id));
  }
}
