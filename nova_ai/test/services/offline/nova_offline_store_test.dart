import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/services/offline/nova_offline_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NovaOfflineStore tasks', () {
    test('saves, updates, reloads, and deletes a task', () async {
      final store = NovaOfflineStore();
      await store.saveTask(const NovaOfflineTask(id: 't1', title: 'Draft plan'));
      await store.saveTask(const NovaOfflineTask(
        id: 't1',
        title: 'Draft plan',
        notes: 'Updated offline',
        isComplete: true,
      ));

      final loaded = await store.loadTasks();
      expect(loaded, hasLength(1));
      expect(loaded.single.notes, 'Updated offline');
      expect(loaded.single.isComplete, isTrue);

      await store.deleteTask('t1');
      expect(await store.loadTasks(), isEmpty);
    });
  });

  group('NovaOfflineStore income plans', () {
    test('persists plan and calculates profit and break-even', () async {
      final store = NovaOfflineStore();
      const plan = NovaIncomePlan(
        id: 'p1',
        name: 'Digital service',
        startupCost: 120,
        monthlyRevenue: 80,
        monthlyCosts: 20,
      );
      await store.saveIncomePlan(plan);

      final loaded = (await store.loadIncomePlans()).single;
      expect(loaded.name, 'Digital service');
      expect(loaded.estimatedMonthlyProfit, 60);
      expect(loaded.estimatedBreakEvenMonths, 2);
    });

    test('does not claim break-even when profit is zero or negative', () {
      const zero = NovaIncomePlan(
        id: 'zero',
        name: 'Zero',
        startupCost: 50,
        monthlyRevenue: 10,
        monthlyCosts: 10,
      );
      const loss = NovaIncomePlan(
        id: 'loss',
        name: 'Loss',
        startupCost: 50,
        monthlyRevenue: 5,
        monthlyCosts: 10,
      );
      expect(zero.estimatedBreakEvenMonths, isNull);
      expect(loss.estimatedBreakEvenMonths, isNull);
    });
  });
}
