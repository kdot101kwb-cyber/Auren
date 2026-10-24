import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auren/features/everyday_life/data/everyday_life_local_store.dart';
import 'package:auren/features/everyday_life/domain/everyday_life_item.dart';
import 'package:auren/features/everyday_life/presentation/auren_everyday_life_screen.dart';

class _FailingReadStore extends EverydayLifeLocalStore {
  @override
  Future<List<EverydayLifeItem>> readAll() async {
    throw StateError('simulated local read failure');
  }
}

class _FailingWriteStore extends EverydayLifeLocalStore {
  @override
  Future<void> save(EverydayLifeItem item) async {
    throw StateError('simulated local persistence failure');
  }

  @override
  Future<void> delete(String id) async {
    throw StateError('simulated local deletion failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenEverydayLifeScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('local data erasure requires confirmation and preserves unrelated settings',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('unrelated_app_setting', 'keep-me');
    await EverydayLifeLocalStore(preferences: preferences).save(
      EverydayLifeItem(
        id: 'private-task',
        kind: EverydayLifeKind.task,
        title: 'Locally saved task',
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: AurenEverydayLifeScreen(
        store: EverydayLifeLocalStore(preferences: preferences),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('إدارة البيانات المحلية'));
    await tester.pumpAndSettle();
    expect(find.text('مسح بيانات الحياة اليومية؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect((await EverydayLifeLocalStore(preferences: preferences).readAll()),
        hasLength(1));

    await tester.tap(find.byTooltip('إدارة البيانات المحلية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مسح البيانات المحلية'));
    await tester.pumpAndSettle();

    expect(await EverydayLifeLocalStore(preferences: preferences).readAll(),
        isEmpty);
    expect(preferences.getString('unrelated_app_setting'), 'keep-me');
    expect(find.text('تم مسح بيانات الحياة اليومية من هذا الجهاز.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'shows a retry action when local records cannot be read',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AurenEverydayLifeScreen(store: _FailingReadStore()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('تعذر قراءة البيانات المحلية. حاول مرة أخرى.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('تعذر قراءة البيانات المحلية. حاول مرة أخرى.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('organizer creates a local task and can mark it complete',
      (tester) async {
    await openScreen(tester);

    await tester.tap(find.text('أضف مهمة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Call the electrician');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('Call the electrician'), findsOneWidget);
    expect((await EverydayLifeLocalStore().readAll()).single.title,
        'Call the electrician');

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('مكتملة'), findsOneWidget);
  });

  testWidgets('organizer creates a daily list and preserves separate lines',
      (tester) async {
    await openScreen(tester);

    await tester.tap(find.text('أضف قائمة'));
    await tester.pumpAndSettle();
    expect(find.text('إنشاء قائمة يومية'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Shopping');
    await tester.enterText(find.byType(TextField).at(1), 'Bread\nMilk\nSoap');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    final saved = (await EverydayLifeLocalStore().readAll()).single;
    expect(saved.kind.name, 'taskList');
    expect(saved.details, 'Bread\nMilk\nSoap');
    expect(find.textContaining('عناصر القائمة'), findsOneWidget);
  });

  testWidgets('appointment request is stored as an unsent draft',
      (tester) async {
    await openScreen(tester);

    await tester.tap(find.text('Appointments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء مسودة طلب'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Request a plumbing visit');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('Request a plumbing visit'), findsOneWidget);
    expect(find.textContaining('لم يُرسل ولم يُؤكَّد أي موعد'), findsOneWidget);
    final records = await EverydayLifeLocalStore().readAll();
    expect(records.single.kind.name, 'appointmentDraft');
    expect(records.single.providerName, isEmpty);
    expect(records.single.dueAt, isNull);
  });

  testWidgets('household chores, supplies, and maintenance save their entered details',
      (tester) async {
    await openScreen(tester);

    await tester.ensureVisible(find.text('Home'));
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضف مهمة منزلية'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Clean kitchen');
    await tester.enterText(find.byType(TextField).at(1), 'User-entered chore details');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    var records = await EverydayLifeLocalStore().readAll();
    expect(records.single.kind, EverydayLifeKind.household);
    expect(records.single.details, 'User-entered chore details');

    await tester.ensureVisible(find.text('Supplies'));
    await tester.tap(find.text('Supplies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضف مستلزم منزلي'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Laundry detergent');
    await tester.enterText(find.byType(TextField).at(1), 'Keep in the laundry room');
    await tester.enterText(find.byType(TextField).at(2), '2 bottles');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    records = await EverydayLifeLocalStore().readAll();
    final supply = records.singleWhere((item) => item.kind == EverydayLifeKind.householdSupply);
    expect(supply.title, 'Laundry detergent');
    expect(supply.details, 'Keep in the laundry room');
    expect(supply.quantity, '2 bottles');

    await tester.ensureVisible(find.text('Maintenance'));
    await tester.tap(find.text('Maintenance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضف مهمة صيانة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Repair kitchen tap');
    await tester.enterText(find.byType(TextField).at(1), 'Tap is leaking');
    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.decoration?.labelText?.startsWith('الوقت المطلوب') == true),
      'Friday afternoon',
    );
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    records = await EverydayLifeLocalStore().readAll();
    final maintenance = records.singleWhere(
      (item) => item.kind == EverydayLifeKind.householdMaintenance,
    );
    expect(maintenance.title, 'Repair kitchen tap');
    expect(maintenance.details, 'Tap is leaking');
    expect(maintenance.requestedWindow, 'Friday afternoon');
    expect(maintenance.dueAt, isNull);
  });

  testWidgets('local directory entry defaults to unconfirmed and can be unverified',
      (tester) async {
    await openScreen(tester);

    await tester.ensureVisible(find.text('Local services'));
    await tester.tap(find.text('Local services'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضف خدمة بنفسك'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Electrician - entered by me');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('معلومات غير مؤكدة'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('وضع علامة: تحققت منه'));
    await tester.pumpAndSettle();
    expect(find.text('وضع المستخدم علامة التحقق'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إزالة علامة التحقق'));
    await tester.pumpAndSettle();
    expect(find.text('معلومات غير مؤكدة'), findsOneWidget);
  });

  testWidgets('local service favorite and delete changes persist locally',
      (tester) async {
    await openScreen(tester);

    await tester.ensureVisible(find.text('Local services'));
    await tester.tap(find.text('Local services'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضف خدمة بنفسك'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'User-entered tailor');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    var records = await EverydayLifeLocalStore().readAll();
    expect(records, hasLength(1));
    expect(records.single.favorite, isFalse);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة للمفضلة'));
    await tester.pumpAndSettle();

    records = await EverydayLifeLocalStore().readAll();
    expect(records.single.favorite, isTrue);
    expect(find.textContaining('مفضلة'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(find.text('حذف هذا العنصر؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(await EverydayLifeLocalStore().readAll(), hasLength(1));

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف العنصر'));
    await tester.pumpAndSettle();

    expect(await EverydayLifeLocalStore().readAll(), isEmpty);
    expect(find.text('لا توجد عناصر بعد. أضف أول عنصر واحفظه محلياً.'), findsOneWidget);
  });


  testWidgets(
      'failed local mutation keeps the previous state and shows retry guidance',
      (tester) async {
    final persisted = EverydayLifeItem(
      id: 'existing-task',
      kind: EverydayLifeKind.task,
      title: 'Keep this task unchanged',
      completed: false,
    );
    await EverydayLifeLocalStore().save(persisted);
    await tester.pumpWidget(MaterialApp(
      home: AurenEverydayLifeScreen(store: _FailingWriteStore()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(
      find.text('تعذر حفظ التغيير محلياً؛ احتفظنا بالبيانات السابقة. حاول مرة أخرى.'),
      findsOneWidget,
    );
    final records = await EverydayLifeLocalStore().readAll();
    expect(records, hasLength(1));
    expect(records.single.completed, isFalse);
    expect(find.text('Keep this task unchanged'), findsOneWidget);
  });

  testWidgets(
      'failed local service favorite and delete preserve the previous record',
      (tester) async {
    final persisted = EverydayLifeItem(
      id: 'existing-service',
      kind: EverydayLifeKind.localService,
      title: 'Keep this service unchanged',
      favorite: false,
      informationConfirmed: false,
    );
    await EverydayLifeLocalStore().save(persisted);
    await tester.pumpWidget(MaterialApp(
      home: AurenEverydayLifeScreen(store: _FailingWriteStore()),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Local services'));
    await tester.tap(find.text('Local services'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة للمفضلة'));
    await tester.pumpAndSettle();
    expect(
      find.text('تعذر حفظ التغيير محلياً؛ احتفظنا بالبيانات السابقة. حاول مرة أخرى.'),
      findsOneWidget,
    );
    expect((await EverydayLifeLocalStore().readAll()).single.favorite, isFalse);
    expect(find.text('Keep this service unchanged'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف العنصر'));
    await tester.pumpAndSettle();
    expect(
      find.text('تعذر حفظ التغيير محلياً؛ احتفظنا بالبيانات السابقة. حاول مرة أخرى.'),
      findsOneWidget,
    );
    final records = await EverydayLifeLocalStore().readAll();
    expect(records, hasLength(1));
    expect(records.single.id, 'existing-service');
    expect(records.single.favorite, isFalse);
    expect(find.text('Keep this service unchanged'), findsOneWidget);
  });

  testWidgets(
      'failed local create shows an error and does not add a record',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AurenEverydayLifeScreen(store: _FailingWriteStore()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('أضف مهمة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Task that cannot be saved');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر الحفظ على هذا الجهاز.'), findsOneWidget);
    expect(await EverydayLifeLocalStore().readAll(), isEmpty);
    expect(find.text('Task that cannot be saved'), findsNothing);
  });

  testWidgets('household supplies expose and persist the user-entered category',
      (tester) async {
    await openScreen(tester);

    await tester.ensureVisible(find.text('Supplies'));
    await tester.tap(find.text('Supplies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضف مستلزم منزلي'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Laundry detergent');
    await tester.enterText(find.byType(TextField).at(2), '2 bottles');
    await tester.enterText(find.byType(TextField).at(3), 'Cleaning');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    final records = await EverydayLifeLocalStore().readAll();
    expect(records, hasLength(1));
    expect(records.single.title, 'Laundry detergent');
    expect(records.single.quantity, '2 bottles');
    expect(records.single.category, 'Cleaning');
    expect(find.textContaining('التصنيف: Cleaning'), findsOneWidget);
  });

}
