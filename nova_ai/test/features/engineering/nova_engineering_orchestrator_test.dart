import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/engineering/nova_engineering_orchestrator.dart';

void main() {
  const orchestrator = NovaEngineeringOrchestrator();

  test('routes Flutter and Android build work to relevant engineers', () {
    final assignment = orchestrator.plan('Fix Flutter screen and Android APK build');
    expect(assignment.roles, contains(NovaEngineeringRole.flutterUi));
    expect(assignment.roles, contains(NovaEngineeringRole.buildRelease));
    expect(assignment.roles, contains(NovaEngineeringRole.testEngineer));
    expect(assignment.roles, contains(NovaEngineeringRole.codeReviewer));
  });

  test('routes Firebase permissions work through security and backend', () {
    final assignment = orchestrator.plan('Review Firebase auth permissions and API');
    expect(assignment.roles, contains(NovaEngineeringRole.security));
    expect(assignment.roles, contains(NovaEngineeringRole.backendApi));
    expect(assignment.risk, NovaEngineeringRisk.medium);
  });

  test('marks deploy and payment tasks high risk and approval gated', () {
    final assignment = orchestrator.plan('Deploy production and verify payment transfer');
    expect(assignment.risk, NovaEngineeringRisk.high);
    expect(assignment.requiresHumanApproval, isTrue);
  });

  test('generic goal still gets architecture, tests and review', () {
    final assignment = orchestrator.plan('Improve the project');
    expect(assignment.roles, contains(NovaEngineeringRole.architect));
    expect(assignment.roles, contains(NovaEngineeringRole.testEngineer));
    expect(assignment.roles, contains(NovaEngineeringRole.codeReviewer));
  });

  test('rejects an empty goal', () {
    expect(() => orchestrator.plan('  '), throwsArgumentError);
  });
}
