import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/entertainment/domain/auren_interactive_story.dart';

void main() {
  group('AurenInteractiveStory', () {
    test('starts at a node with multiple meaningful choices', () {
      final start = AurenInteractiveStory.node(AurenInteractiveStory.startNodeId);
      expect(start.choices.length, greaterThanOrEqualTo(3));
      expect(start.ending, isNull);
    });

    test('choices lead to valid nodes and endings', () {
      final workshop = AurenInteractiveStory.choose('arrival', 'build');
      expect(workshop.id, 'workshop');
      final ending = AurenInteractiveStory.choose('workshop', 'prototype');
      expect(ending.ending, AurenStoryEnding.creator);
    });

    test('alternative choices lead to different endings', () {
      final creator = AurenInteractiveStory.choose('workshop', 'prototype');
      final connector = AurenInteractiveStory.choose('workshop', 'share');
      expect(creator.ending, AurenStoryEnding.creator);
      expect(connector.ending, AurenStoryEnding.connector);
    });

    test('emotion realm offers creative and empathetic paths', () {
      final realm = AurenInteractiveStory.choose('wilds', 'mirror');
      expect(realm.id, 'emotion_realm');
      expect(
        AurenInteractiveStory.choose(realm.id, 'turn_emotion_into_art').ending,
        AurenStoryEnding.creator,
      );
      expect(
        AurenInteractiveStory.choose(realm.id, 'understand_others').ending,
        AurenStoryEnding.connector,
      );
    });

    test('city archive offers a privacy-respecting guardian ending', () {
      final archive = AurenInteractiveStory.choose('plaza', 'secret');
      expect(archive.id, 'city_archive');
      expect(
        AurenInteractiveStory.choose(archive.id, 'protect_stories').ending,
        AurenStoryEnding.guardian,
      );
      expect(
        AurenInteractiveStory.choose(archive.id, 'share_lessons').ending,
        AurenStoryEnding.explorer,
      );
    });

    test('rejects unavailable choices instead of silently branching', () {
      expect(
        () => AurenInteractiveStory.choose('arrival', 'prototype'),
        throwsArgumentError,
      );
    });

    test('all choices point to existing nodes', () {
      for (final nodeId in AurenInteractiveStory.nodeIds) {
        final node = AurenInteractiveStory.node(nodeId);
        for (final choice in node.choices) {
          expect(
            AurenInteractiveStory.nodes.containsKey(choice.nextNodeId),
            isTrue,
          );
        }
      }
    });
  });
}
