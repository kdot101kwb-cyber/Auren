import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/social/match_everything_service.dart';

void main() {
  group('AurenIntentSignals', () {
    test('detects Arabic and English commercial signals', () {
      final s = AurenIntentSignals.fromIntent('عايز مصنع ملابس في الصين بسعر رخيص مع الشحن');
      expect(s.countries, contains('الصين'));
      expect(s.wantsManufacturer, isTrue);
      expect(s.wantsCheap, isTrue);
      expect(s.wantsShipping, isTrue);
      expect(s.matchScore('مصنع ملابس الصين shipping cheap'), greaterThan(0));
    });

    test('detects location signals', () {
      final s = AurenIntentSignals.fromIntent('supplier in Khartoum, Sudan');
      expect(s.countries, contains('sudan'));
      expect(s.cities, contains('khartoum'));
      expect(s.wantsSupplier, isTrue);
    });
  });

  group('AurenIntentActionPlan', () {
    test('maps supplier intent to quote request', () {
      final plan = AurenIntentActionPlan.fromIntent('أبحث عن مورد في الصين');
      expect(plan.actionFor(AurenMatchKind.business), AurenMatchAction.requestQuote);
    });

    test('maps purchase intent to cart', () {
      final plan = AurenIntentActionPlan.fromIntent('أريد شراء منتج');
      expect(plan.actionFor(AurenMatchKind.product), AurenMatchAction.addToCart);
    });

    test('maps job intent to application', () {
      final plan = AurenIntentActionPlan.fromIntent('أبحث عن وظيفة');
      expect(plan.actionFor(AurenMatchKind.opportunity), AurenMatchAction.apply);
    });

    test('maps media intent to watch', () {
      final plan = AurenIntentActionPlan.fromIntent('أريد مشاهدة فيلم');
      expect(plan.actionFor(AurenMatchKind.content), AurenMatchAction.watch);
    });

    test('maps social intent to contact', () {
      final plan = AurenIntentActionPlan.fromIntent('أريد التواصل مع مؤثر');
      expect(plan.actionFor(AurenMatchKind.person), AurenMatchAction.contact);
    });
  });

  test('normalizes Arabic spelling variants for intent signals', () {
    final signals = AurenIntentSignals.fromIntent('أرخص مورد ملابس في الإمارات');
    expect(signals.wantsCheap, isTrue);
    expect(signals.wantsSupplier, isTrue);
    expect(signals.countries, contains('الامارات'));
  });
}
