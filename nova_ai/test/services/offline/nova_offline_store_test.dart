import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/services/offline/nova_offline_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('NovaOfflineStore tasks', () {
    test('saves, updates, persists, and deletes a task', () async {
      final store = NovaOfflineStore();
      await store.saveTask(const NovaOfflineTask(
        id: 'task-1',
        title: 'Review opportunity',
      ));

      await store.saveTask(const NovaOfflineTask(
        id: 'task-1',
        title: 'Review opportunity',
        notes: 'Check source and deadline',
        isComplete: true,
      ));

      final loaded = await NovaOfflineStore().getTasks();
      expect(loaded, hasLength(1));
      expect(loaded.single.notes, 'Check source and deadline');
      expect(loaded.single.isComplete, isTrue);

      await store.deleteTask('task-1');
      expect(await store.getTasks(), isEmpty);
    });
  });

  group('NovaOfflineStore income plans', () {
    test('persists plan and calculates profit and break-even', () async {
      final store = NovaOfflineStore();
      await store.saveIncomePlan(const NovaIncomePlan(
        id: 'plan-1',
        name: 'Freelance service',
        monthlyRevenue: 300,
        monthlyCosts: 50,
        initialInvestment: 500,
      ));

      final plan = (await NovaOfflineStore().getIncomePlans()).single;
      expect(plan.estimatedMonthlyProfit, 250);
      expect(plan.estimatedBreakEvenMonths, 2);
      expect(plan.currency, 'USD');
    });

    test('does not invent a break-even date when profit is not positive',
        () {
      const plan = NovaIncomePlan(
        id: 'plan-loss',
        name: 'Not profitable yet',
        monthlyRevenue: 100,
        monthlyCosts: 120,
      );
      expect(plan.estimatedMonthlyProfit, -20);
      expect(plan.estimatedBreakEvenMonths, isNull);
    });
  });
}
