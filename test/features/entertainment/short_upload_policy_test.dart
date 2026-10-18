import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/entertainment/short_upload_policy.dart';

void main() {
  group('AurenShortUploadPolicy', () {
    test('accepts MP4 names without case sensitivity', () {
      expect(AurenShortUploadPolicy.isMp4FileName('clip.mp4'), isTrue);
      expect(AurenShortUploadPolicy.isMp4FileName('CLIP.MP4'), isTrue);
      expect(AurenShortUploadPolicy.isMp4FileName('clip.mov'), isFalse);
      expect(AurenShortUploadPolicy.isMp4FileName('clip.mp4.exe'), isFalse);
    });

    test('enforces positive file size and the 25 MiB limit', () {
      expect(AurenShortUploadPolicy.isValidFileSize(1), isTrue);
      expect(
        AurenShortUploadPolicy.isValidFileSize(AurenShortUploadPolicy.maxBytes),
        isTrue,
      );
      expect(AurenShortUploadPolicy.isValidFileSize(0), isFalse);
      expect(
        AurenShortUploadPolicy.isValidFileSize(
          AurenShortUploadPolicy.maxBytes + 1,
        ),
        isFalse,
      );
    });

    test('enforces positive duration up to three minutes', () {
      expect(
        AurenShortUploadPolicy.isValidDuration(const Duration(seconds: 1)),
        isTrue,
      );
      expect(
        AurenShortUploadPolicy.isValidDuration(
          AurenShortUploadPolicy.maxDuration,
        ),
        isTrue,
      );
      expect(
        AurenShortUploadPolicy.isValidDuration(Duration.zero),
        isFalse,
      );
      expect(
        AurenShortUploadPolicy.isValidDuration(
          AurenShortUploadPolicy.maxDuration + const Duration(milliseconds: 1),
        ),
        isFalse,
      );
    });

    test('validates title and description boundaries', () {
      expect(AurenShortUploadPolicy.validateTitle('  عنوان  '), isNull);
      expect(AurenShortUploadPolicy.validateTitle('   '), isNotNull);
      expect(
        AurenShortUploadPolicy.validateTitle('a' * 160),
        isNull,
      );
      expect(
        AurenShortUploadPolicy.validateTitle('a' * 161),
        isNotNull,
      );
      expect(
        AurenShortUploadPolicy.validateDescription('a' * 3000),
        isNull,
      );
      expect(
        AurenShortUploadPolicy.validateDescription('a' * 3001),
        isNotNull,
      );
    });

    test('accepts only Firestore-approved categories and moods', () {
      expect(
        AurenShortUploadPolicy.isAllowedCategory('كوميديا'),
        isTrue,
      );
      expect(
        AurenShortUploadPolicy.isAllowedCategory('غير معروف'),
        isFalse,
      );
      expect(AurenShortUploadPolicy.isAllowedMood('ضحك'), isTrue);
      expect(AurenShortUploadPolicy.isAllowedMood('مزاج غير معروف'), isFalse);
    });
  });
}
