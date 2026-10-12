import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/talent/talent_skill_matcher.dart';

void main() {
  group('TalentSkillMatcher', () {
    test('normalizes case, whitespace, punctuation, and Arabic text', () {
      expect(TalentSkillMatcher.normalize('  Flutter-DEVELOPER  '), 'flutter developer');
      expect(TalentSkillMatcher.normalize('تحليل   البيانات'), 'تحليل البيانات');
    });

    test('scores only the supplied verified skills', () {
      final result = TalentSkillMatcher.evaluate(
        verifiedSkills: ['Flutter', 'Dart'],
        requiredSkills: ['flutter', 'Dart', 'Firebase', ''],
      );
      expect(result.score, 67);
      expect(result.matchedSkills, ['dart', 'flutter']);
      expect(result.missingSkills, ['firebase']);
    });

    test('deduplicates equivalent skills', () {
      final result = TalentSkillMatcher.evaluate(
        verifiedSkills: ['Python', 'python'],
        requiredSkills: ['Python', ' python ', ''],
      );
      expect(result.score, 100);
      expect(result.matchedSkills, ['python']);
      expect(result.missingSkills, isEmpty);
    });

    test('empty requirements have zero score', () {
      final result = TalentSkillMatcher.evaluate(
        verifiedSkills: ['Flutter'],
        requiredSkills: ['', '   '],
      );
      expect(result.score, 0);
      expect(result.matchedSkills, isEmpty);
      expect(result.missingSkills, isEmpty);
    });

    test('missing skills are explicit and sorted', () {
      final result = TalentSkillMatcher.evaluate(
        verifiedSkills: ['Dart'],
        requiredSkills: ['Firebase', 'Dart', 'Flutter'],
      );
      expect(result.score, 33);
      expect(result.matchedSkills, ['dart']);
      expect(result.missingSkills, ['firebase', 'flutter']);
    });
  });
}
