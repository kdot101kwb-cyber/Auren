import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/main.dart';

void main() {
  testWidgets('NOVA dashboard exposes main sections', (tester) async {
    await tester.pumpWidget(const NovaApp());
    expect(find.text('NOVA AI'), findsOneWidget);
    expect(find.text('مركز القيادة الذكي'), findsOneWidget);
    expect(find.text('الوكلاء'), findsWidgets);
    expect(find.text('AUREN'), findsOneWidget);
  });
}
