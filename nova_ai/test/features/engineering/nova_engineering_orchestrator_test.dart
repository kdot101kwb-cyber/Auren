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

  test('Arabic speed wording does not trigger a false high-risk classification', () {
    final assignment = orchestrator.plan('تسريع التطبيق وتحسين الأداء');
    expect(assignment.risk, NovaEngineeringRisk.low);
    expect(assignment.requiresHumanApproval, isTrue);
  });

  test('explicit Arabic secret wording is classified as high risk', () {
    final assignment = orchestrator.plan('راجع الأسرار والمفتاح السري');
    expect(assignment.risk, NovaEngineeringRisk.high);
  });

  test('Arabic diacritics and alef variants do not bypass risk detection', () {
    final assignment = orchestrator.plan('تَغْيِير صَلاحِيّات الحساب');
    expect(assignment.risk, NovaEngineeringRisk.high);
    expect(assignment.requiresHumanApproval, isTrue);
  });

  test('Arabic delete and send requests are high risk', () {
    expect(orchestrator.plan('احذف الحساب').risk, NovaEngineeringRisk.high);
    expect(orchestrator.plan('إرسال رسالة للعملاء').risk, NovaEngineeringRisk.high);
  });

  test('rejects an empty goal', () {
    expect(() => orchestrator.plan('  '), throwsArgumentError);
  });
}
