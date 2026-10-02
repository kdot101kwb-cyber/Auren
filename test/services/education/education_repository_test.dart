import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/education/education_repository.dart';

void main() {
  group('EducationRepository.progressFor', () {
    test('returns zero at the start', () {
      expect(EducationRepository.progressFor(0, 10), 0);
    });

    test('calculates rounded percentage', () {
      expect(EducationRepository.progressFor(1, 3), 33);
      expect(EducationRepository.progressFor(2, 3), 67);
      expect(EducationRepository.progressFor(3, 3), 100);
    });

    test('rejects invalid lesson counts', () {
      expect(() => EducationRepository.progressFor(0, 0), throwsArgumentError);
      expect(() => EducationRepository.progressFor(-1, 10), throwsArgumentError);
      expect(() => EducationRepository.progressFor(11, 10), throwsArgumentError);
    });
  });
}
