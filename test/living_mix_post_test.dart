import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/models/post.dart';
import 'package:auren/features/social/presentation/living_mix_screen.dart';

void main() {
  group('AurenPost Living Moments and Mix Posts', () {
    test('round-trips mix blocks and living metadata', () {
      final original = AurenPost(
        id: 'living_1',
        authorId: 'user_1',
        text: 'A market is opening',
        createdAt: DateTime.utc(2026, 10, 19),
        contentType: 'living',
        postFormat: 'living',
        livingStatus: 'active',
        livingSummary: 'Follow the market launch',
        mixBlocks: const [
          {'type': 'text', 'value': 'First update'},
          {'type': 'link', 'value': 'https://example.com'},
        ],
      );

      final restored = AurenPost.fromMap(original.id, original.toMap());

      expect(restored.contentType, 'living');
      expect(restored.postFormat, 'living');
      expect(restored.livingStatus, 'active');
      expect(restored.livingSummary, 'Follow the market launch');
      expect(restored.mixBlocks, hasLength(2));
      expect(restored.mixBlocks.last['type'], 'link');
      expect(restored.mixBlocks.last['value'], 'https://example.com');
    });

    test('defaults old posts to standard format without blocks', () {
      final restored = AurenPost.fromMap('old_post', {
        'authorId': 'user_1',
        'text': 'Legacy post',
        'createdAt': '2026-10-19T00:00:00.000Z',
      });

      expect(restored.postFormat, 'standard');
      expect(restored.mixBlocks, isEmpty);
      expect(restored.livingStatus, 'active');
      expect(restored.livingSummary, isEmpty);
    });
  });

  testWidgets('composer exposes both Living and Mix formats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenLivingMixComposerScreen()),
    );

    expect(find.text('Create Mix Post'), findsOneWidget);
    expect(find.text('Living Moment'), findsOneWidget);
    expect(find.text('Mix Post'), findsOneWidget);

    await tester.tap(find.text('Image URL'));
    await tester.pumpAndSettle();

    expect(find.text('Image URL'), findsWidgets);
    expect(find.text('https://…/image.jpg'), findsOneWidget);
  });
}
