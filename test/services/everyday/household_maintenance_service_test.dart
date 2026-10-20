import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/everyday/household_maintenance_service.dart';

void main() {
  final due = DateTime(2026, 11, 2);

  AurenMaintenanceTask task(
    String id,
    String title, {
    DateTime? dueAt,
    AurenMaintenanceStatus status = AurenMaintenanceStatus.planned,
    int? estimate,
    int? actual,
  }) => AurenMaintenanceTask(
    id: id,
    title: title,
    area: 'Kitchen',
    dueAt: dueAt,
    status: status,
    estimatedCostMinor: estimate,
    actualCostMinor: actual,
  );

  test('validates required fields, lengths and costs', () {
    expect(task(' ', 'Repair').validate(), isNotNull);
    expect(task('1', ' ').validate(), isNotNull);
    expect(AurenMaintenanceTask(
      id: '1', title: 'Repair', area: 'Kitchen', estimatedCostMinor: -1,
    ).validate(), isNotNull);
    expect(task('1', 'Repair', actual: 500).validate(), isNotNull);
    expect(task('1', 'Repair', status: AurenMaintenanceStatus.completed, actual: 500).validate(), isNull);
  });

  test('active tasks omit completed, cancelled and invalid entries', () {
    final tasks = [
      task('1', 'No date'),
      task('2', 'Later', dueAt: due.add(const Duration(days: 2))),
      task('3', 'Soon', dueAt: due),
      task('4', 'Done', status: AurenMaintenanceStatus.completed),
      task('5', 'Cancelled', status: AurenMaintenanceStatus.cancelled),
      task(' ', 'Invalid'),
    ];
    expect(
      AurenMaintenancePlanner.activeTasks(tasks).map((e) => e.title).toList(),
      ['Soon', 'Later', 'No date'],
    );
  });

  test('totals valid estimated costs and skips missing or invalid costs', () {
    expect(AurenMaintenancePlanner.totalEstimatedCostMinor([
      task('1', 'Tap', estimate: 2500),
      task('2', 'Door', estimate: 700),
      task('3', 'Window'),
      AurenMaintenanceTask(id: '4', title: 'Bad', area: 'Home', estimatedCostMinor: -2),
    ]), 3200);
    expect(AurenMaintenancePlanner.totalEstimatedCostMinor([]), 0);
  });

  test('copyWith can clear optional dates and actual costs', () {
    final original = task('1', 'Repair', dueAt: due,
      status: AurenMaintenanceStatus.completed, actual: 1200);
    final updated = original.copyWith(clearDueAt: true, clearActualCost: true);
    expect(updated.dueAt, isNull);
    expect(updated.actualCostMinor, isNull);
    expect(updated.title, 'Repair');
  });
}
