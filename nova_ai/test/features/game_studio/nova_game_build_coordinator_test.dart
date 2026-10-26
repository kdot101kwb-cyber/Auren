import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/game_studio/nova_game_build_coordinator.dart';
import 'package:nova_ai/features/game_studio/nova_game_tool_catalog.dart';

void main() {
  test('coordinates ten free game-development tools across ordered stages', () {
    final plan = NovaGameBuildCoordinator.createPlan('A 2D treasure adventure');

    expect(plan.engine, 'Godot 4');
    expect(plan.tasks.map((task) => task.order).toList(), [1, 2, 3, 4, 5, 6]);
    expect(NovaGameBuildCoordinator.defaultToolChain, hasLength(10));
    expect(NovaGameBuildCoordinator.defaultToolChain.toSet(), hasLength(10));
    for (final id in NovaGameBuildCoordinator.defaultToolChain) {
      expect(NovaGameToolCatalog.tools.any((tool) => tool.id == id), isTrue,
          reason: 'Missing catalogue entry for $id');
    }
    expect(plan.connectedToolIds, containsAll(NovaGameBuildCoordinator.defaultToolChain));
  });

  test('exports a machine-readable plan without claiming execution', () {
    final plan = NovaGameBuildCoordinator.createPlan('Puzzle game');
    final json = jsonDecode(jsonEncode(plan.toJson())) as Map<String, dynamic>;

    expect(json['execution_status'], 'planned_not_executed');
    expect(json['tool_chain'], hasLength(10));
    expect(json['safety']['budget_usd'], 0);
    expect(json['safety']['external_actions'], 'require_user_approval');
    expect((json['tasks'] as List).every(
      (task) => task['execution_status'] == 'planned_not_executed',
    ), isTrue);
  });

  test('rejects an empty idea instead of creating a meaningless plan', () {
    expect(
      () => NovaGameBuildCoordinator.createPlan('   '),
      throwsArgumentError,
    );
  });
}
