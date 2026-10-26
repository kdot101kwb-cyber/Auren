import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/game_studio/nova_game_studio_screen.dart';

void main() {
  testWidgets('generates starter Godot files from an idea', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaGameStudioScreen()));
    await tester.enterText(find.byKey(const Key('game_idea_input')), 'Space Crystal Adventure');
    await tester.tap(find.byKey(const Key('generate_game_button')));
    await tester.pumpAndSettle();
    expect(find.text('project.godot'), findsOneWidget);
    expect(find.text('main.gd'), findsOneWidget);
    expect(find.text('main.tscn'), findsOneWidget);
    expect(find.textContaining('لم يتم تشغيل المحرك'), findsOneWidget);
  });

  testWidgets('search filters game tools', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaGameStudioScreen()));
    await tester.enterText(find.byKey(const Key('game_tools_search')), 'Blender');
    await tester.pumpAndSettle();
    expect(find.text('Blender'), findsOneWidget);
    expect(find.text('Godot Engine'), findsNothing);
  });
}
