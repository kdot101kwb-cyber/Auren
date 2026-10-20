import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/knowledge_notebook/presentation/auren_knowledge_notebook_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Knowledge Notebook saves notes locally', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenKnowledgeNotebookScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('دفترك جاهز'), findsOneWidget);
    await tester.tap(find.text('ملاحظة جديدة'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'مصادر التصنيع');
    await tester.enterText(
      textFields.at(1),
      'تحقق من بيانات الصادرات الزراعية قبل المقارنة.',
    );
    await tester.tap(find.text('حفظ الملاحظة'));
    await tester.pumpAndSettle();

    expect(find.text('مصادر التصنيع'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('auren_knowledge_notebook_v1'),
      contains('تحقق من بيانات الصادرات الزراعية'),
    );
  });

  testWidgets('Knowledge Notebook clearly states that notes stay on device', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenKnowledgeNotebookScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('محفوظة على هذا الجهاز فقط'), findsOneWidget);
  });
}
