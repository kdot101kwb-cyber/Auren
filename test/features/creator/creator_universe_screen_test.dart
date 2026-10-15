import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/creator/presentation/creator_universe_screen.dart';

void main() {
  testWidgets('creator universe shows the integrated creator entry points', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenCreatorUniverseScreen()),
    );

    expect(find.text('AUREN Creator Universe'), findsOneWidget);
    expect(find.text('Creator Studio'), findsOneWidget);
    expect(find.text('المسودات ومساعد AI'), findsOneWidget);
    expect(find.text('قنوات وفيديوهات AUREN'), findsOneWidget);
    expect(find.text('استوديو الإنتاج بالذكاء الاصطناعي'), findsOneWidget);
  });
}
