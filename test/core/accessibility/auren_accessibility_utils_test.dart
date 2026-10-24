import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/accessibility/auren_accessibility_utils.dart';

void main() {
  test('text scale is bounded and rejects non-finite input', () {
    expect(AurenAccessibilityUtils.boundedTextScale(0.1), 0.8);
    expect(AurenAccessibilityUtils.boundedTextScale(3), 2.0);
    expect(AurenAccessibilityUtils.boundedTextScale(double.nan), 1.0);
  });

  test('black and white meet AA contrast', () {
    expect(AurenAccessibilityUtils.contrastRatio(0xff000000, 0xffffffff), closeTo(21, 0.01));
    expect(AurenAccessibilityUtils.meetsAa(0xff000000, 0xffffffff), isTrue);
    expect(AurenAccessibilityUtils.meetsAa(0xff777777, 0xffffffff), isFalse);
  });
}
