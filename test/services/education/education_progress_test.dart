import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/education/education_repository.dart';

void main() {
  group('EducationRepository.progressFor', () {
    test('maps zero, partial, and completed lessons to percentage', () {
      expect(EducationRepository.progressFor(0, 4), 0);
      expect(EducationRepository.progressFor(1, 4), 25);
      expect(EducationRepository.progressFor(3, 4), 75);
      expect(EducationRepository.progressFor(4, 4), 100);
    });

    test('rounds fractional percentages consistently', () {
      expect(EducationRepository.progressFor(1, 3), 33);
      expect(EducationRepository.progressFor(2, 3), 67);
    });

    test('rejects invalid lesson counts and completion values', () {
      expect(() => EducationRepository.progressFor(0, 0), throwsArgumentError);
      expect(() => EducationRepository.progressFor(-1, 4), throwsArgumentError);
      expect(() => EducationRepository.progressFor(5, 4), throwsArgumentError);
    });
  });
}
