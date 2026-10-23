import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auren/features/everyday_life/data/everyday_life_local_store.dart';
import 'package:auren/features/everyday_life/presentation/auren_everyday_life_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenEverydayLifeScreen()));
    await tester.pumpAndSettle();
  }

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

    expect(await EverydayLifeLocalStore().readAll(), isEmpty);
    expect(find.text('لا توجد عناصر بعد. أضف أول عنصر واحفظه محلياً.'), findsOneWidget);
  });

}
