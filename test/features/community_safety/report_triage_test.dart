import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/community_safety/domain/report_triage.dart';

void main() {
  const triage = CommunityReportTriage();

  test('threats and child safety always require urgent human review', () {
    for (final category in [ReportCategory.threat, ReportCategory.childSafety]) {
      final result = triage.assess(SafetyReport(id: 'report', category: category));
      expect(result.priority, TriagePriority.urgentHumanReview);
    }
  });

  test('report volume escalates review without creating an automatic verdict', () {
    final result = triage.assess(const SafetyReport(
      id: 'report',
      category: ReportCategory.spam,
      independentReports: 5,
    ));
    expect(result.priority, TriagePriority.elevated);
    expect(result.reasons, contains('Multiple reports need review, not an automatic verdict'));
  });

  test('evidence references require verification and harassment is elevated', () {
    final result = triage.assess(const SafetyReport(
      id: 'report',
      category: ReportCategory.harassment,
      hasEvidenceReference: true,
    ));
    expect(result.priority, TriagePriority.elevated);
    expect(result.reasons, contains('Evidence needs independent verification'));
  });

  test('ordinary single reports remain routine', () {
    final result = triage.assess(const SafetyReport(
      id: 'report',
      category: ReportCategory.spam,
    ));
    expect(result.priority, TriagePriority.routine);
    expect(result.reasons, isEmpty);
  });
}
