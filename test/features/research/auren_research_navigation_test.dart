import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/research/presentation/auren_research_desk_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Research Desk opens and returns from each companion workspace',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenResearchDeskScreen()),
    );

    final destinations = <({String title, String appBar})>[
      (title: 'AUREN Knowledge Hub', appBar: 'AUREN Knowledge Hub'),
      (
        title: 'AUREN Knowledge Notebook',
        appBar: 'AUREN Knowledge Notebook',
      ),
      (title: 'AUREN Source Registry', appBar: 'AUREN Source Registry'),
      (title: 'AUREN Language Bridge', appBar: 'AUREN Language Bridge'),
    ];

    for (final destination in destinations) {
      await tester.scrollUntilVisible(
        find.text(destination.title),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(destination.title));
      await tester.pumpAndSettle();

      expect(find.text(destination.appBar), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('AUREN Research Desk'), findsOneWidget);
    }
  });
}
