import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/entertainment/auren_music_prompt_parser.dart';

void main() {
  group('AurenMusicPromptParser.durationMinutes', () {
    test('parses English hours and decimal hours', () {
      expect(AurenMusicPromptParser.durationMinutes('music for 2 hours'), 120);
      expect(AurenMusicPromptParser.durationMinutes('1.5 hrs'), 90);
    });

    test('parses Arabic duration and Arabic-Indic digits', () {
      expect(AurenMusicPromptParser.durationMinutes('موسيقى لمدة ساعتين'), 120);
      expect(AurenMusicPromptParser.durationMinutes('موسيقى لمدة نصف ساعة'), 30);
      expect(AurenMusicPromptParser.durationMinutes('موسيقى لمدة ساعة'), 60);
      expect(AurenMusicPromptParser.durationMinutes('لمدة ٢ ساعة'), 120);
      expect(AurenMusicPromptParser.durationMinutes('لمدة ٣٠ دقيقة'), 30);
    });

    test('clamps duration to supported limits', () {
      expect(AurenMusicPromptParser.durationMinutes('2 minutes'), 10);
      expect(AurenMusicPromptParser.durationMinutes('999 minutes'), 240);
      expect(AurenMusicPromptParser.durationMinutes('9 hours'), 240);
    });

    test('returns null when no duration is present', () {
      expect(AurenMusicPromptParser.durationMinutes('موسيقى هادئة للسفر'), isNull);
    });
  });

  test('searchableWords splits spaces, tabs and newlines', () {
    expect(
      AurenMusicPromptParser.searchableWords('  Calm\n music\tfor a trip  '),
      ['calm', 'music', 'for', 'trip'],
    );
  });
}
