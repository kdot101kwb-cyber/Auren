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

  test('detects export, import, and wholesale sourcing intent', () {
    expect(AurenIntentSignals.fromIntent('exporter for sesame').wantsExporter, isTrue);
    expect(AurenIntentSignals.fromIntent('importer in Sudan').wantsImporter, isTrue);
    expect(AurenIntentSignals.fromIntent('wholesale clothing').wantsWholesale, isTrue);
  });

  test('recognizes more global markets and cities', () {
    final signals = AurenIntentSignals.fromIntent(
      'certified sesame supplier in Nairobi, Kenya shipping to Saudi Arabia',
    );
    expect(signals.countries, contains('kenya'));
    expect(signals.countries, contains('saudi arabia'));
    expect(signals.cities, contains('nairobi'));
    expect(signals.wantsSupplier, isTrue);
    expect(signals.wantsCertified, isTrue);
    expect(signals.wantsShipping, isTrue);
  });

  test('recognizes organic and sample requirements', () {
    final signals = AurenIntentSignals.fromIntent(
      'عايز مورد منتجات عضوية وعينات قبل طلب الجملة',
    );
    expect(signals.wantsOrganic, isTrue);
    expect(signals.wantsSamples, isTrue);
    expect(signals.wantsWholesale, isTrue);
  });

  test('supplier intent score includes certification and sample requirements', () {
    final signals = AurenIntentSignals.fromIntent('certified organic supplier samples');
    final score = signals.matchScore('certified organic supplier samples');
    expect(signals.wantsCertified, isTrue);
    expect(signals.wantsOrganic, isTrue);
    expect(signals.wantsSamples, isTrue);
    expect(score, greaterThan(0));
    expect(score, lessThanOrEqualTo(35));
  });

  group('AurenIntentActionPlan', () {
    test('maps supplier intent to quote request', () {
      final plan = AurenIntentActionPlan.fromIntent('أبحث عن مورد في الصين');
      expect(plan.actionFor(AurenMatchKind.business), AurenMatchAction.requestQuote);
    });

    test('routes multilingual supplier intent to quote request', () {
      for (final intent in [
        'busco proveedor de algodón orgánico certificado',
        'fournisseur certifié biologique avec livraison',
        'Türkiye üretici organik sertifikalı toptan',
        '有机供应商 认证 批发 运输',
        'I need a certified organic supplier',
      ]) {
        final plan = AurenIntentActionPlan.fromIntent(intent);
        expect(
          plan.actionFor(AurenMatchKind.business),
          AurenMatchAction.requestQuote,
          reason: intent,
        );
      }
    });

    test('maps common non-English work, learning, media and purchase intents', () {
      final work = AurenIntentActionPlan.fromIntent('busco empleo en tecnología');
      expect(work.work, isTrue);
      expect(work.actionFor(AurenMatchKind.opportunity), AurenMatchAction.apply);

      final learning = AurenIntentActionPlan.fromIntent('quiero aprender Flutter con un curso');
      expect(learning.learning, isTrue);

      final media = AurenIntentActionPlan.fromIntent('quiero ver una película');
      expect(media.media, isTrue);
      expect(media.actionFor(AurenMatchKind.content), AurenMatchAction.watch);

      final purchase = AurenIntentActionPlan.fromIntent('ürün satın al');
      expect(purchase.actionFor(AurenMatchKind.product), AurenMatchAction.addToCart);
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

  test('handles null and empty intent safely', () {
    final emptySignals = AurenIntentSignals.fromIntent(null);
    final emptyPlan = AurenIntentActionPlan.fromIntent('');
    expect(emptySignals.countries, isEmpty);
    expect(emptySignals.wantsSupplier, isFalse);
    expect(emptyPlan.normalized, isEmpty);
    expect(emptyPlan.actionFor(AurenMatchKind.person), AurenMatchAction.open);
    expect(emptyPlan.actionFor(AurenMatchKind.opportunity), AurenMatchAction.follow);
    expect(emptyPlan.actionFor(AurenMatchKind.business), AurenMatchAction.contact);
    expect(emptyPlan.actionFor(AurenMatchKind.product), AurenMatchAction.contact);
    expect(emptyPlan.actionFor(AurenMatchKind.content), AurenMatchAction.watch);
  });

  test('does not award sourcing relevance to unrelated text', () {
    final signals = AurenIntentSignals.fromIntent(
      'certified organic sesame supplier in Sudan with shipping and samples',
    );
    expect(signals.matchScore('romantic movie about London'), 0);
  });

  test('recognizes Sudanese and regional trade wording', () {
    final signals = AurenIntentSignals.fromIntent(
      'عايز مصدر صمغ عربي من أم درمان للتصدير مع عينات',
    );
    expect(signals.cities, contains('ام درمان'));
    expect(signals.wantsExporter, isTrue);
    expect(signals.wantsSamples, isTrue);
  });

  test('matches equivalent country and city spellings in supplier data', () {
    final countrySignals =
        AurenIntentSignals.fromIntent('manufacturer in Türkiye');
    expect(countrySignals.countries, contains('türkiye'));
    expect(countrySignals.matchingCountries('manufacturer country: Turkey'),
        contains('türkiye'));

    final citySignals =
        AurenIntentSignals.fromIntent('supplier in أم درمان');
    expect(citySignals.matchingCities('city: Omdurman'), contains('ام درمان'));

    final uaeSignals = AurenIntentSignals.fromIntent('supplier in UAE');
    expect(
      uaeSignals.matchingCountries('country: United Arab Emirates'),
      contains('uae'),
    );
  });

  test('recognizes supplier intent across the user\'s language', () {
    final spanish = AurenIntentSignals.fromIntent(
      'busco proveedor de algodón orgánico certificado con envío',
    );
    expect(spanish.wantsSupplier, isTrue);
    expect(spanish.wantsOrganic, isTrue);
    expect(spanish.wantsCertified, isTrue);
    expect(spanish.wantsShipping, isTrue);

    final french = AurenIntentSignals.fromIntent(
      'fournisseur certifié biologique avec livraison et échantillons',
    );
    expect(french.wantsSupplier, isTrue);
    expect(french.wantsCertified, isTrue);
    expect(french.wantsOrganic, isTrue);
    expect(french.wantsShipping, isTrue);
    expect(french.wantsSamples, isTrue);

    final turkish = AurenIntentSignals.fromIntent(
      'Türkiye üretici organik sertifikalı toptan kargo',
    );
    expect(turkish.wantsManufacturer, isTrue);
    expect(turkish.wantsOrganic, isTrue);
    expect(turkish.wantsCertified, isTrue);
    expect(turkish.wantsWholesale, isTrue);
    expect(turkish.wantsShipping, isTrue);

    final chinese = AurenIntentSignals.fromIntent('有机供应商 认证 批发 运输');
    expect(chinese.wantsSupplier, isTrue);
    expect(chinese.wantsOrganic, isTrue);
    expect(chinese.wantsCertified, isTrue);
    expect(chinese.wantsWholesale, isTrue);
    expect(chinese.wantsShipping, isTrue);
  });

  test('recognizes supplier terms and constraints in English', () {
    final signals = AurenIntentSignals.fromIntent(
      'manufacturer of organic cotton in Türkiye, certified, bulk MOQ, delivery',
    );
    expect(signals.countries, contains('türkiye'));
    expect(signals.wantsManufacturer, isTrue);
    expect(signals.wantsOrganic, isTrue);
    expect(signals.wantsCertified, isTrue);
    expect(signals.wantsBulk, isTrue);
    expect(signals.wantsShipping, isTrue);
  });

  test('routes multilingual purchase phrases to the cart action', () {
    for (final intent in [
      'quiero comprar',
      'je veux acheter',
      'quero comprar',
      'ürün satın al',
      'nunua',
      '购买',
      'खरीदें',
    ]) {
      final plan = AurenIntentActionPlan.fromIntent(intent);
      expect(
        plan.actionFor(AurenMatchKind.product),
        AurenMatchAction.addToCart,
        reason: intent,
      );
    }
  });

  test('routes multilingual supplier requests to quote drafts', () {
    for (final intent in [
      'busco proveedor',
      'je cherche un fournisseur',
      'quero fornecedor',
      'tedarikçi arıyorum',
      'msambazaji',
      '寻找供应商',
      'आपूर्तिकर्ता',
    ]) {
      final plan = AurenIntentActionPlan.fromIntent(intent);
      expect(
        plan.actionFor(AurenMatchKind.business),
        AurenMatchAction.requestQuote,
        reason: intent,
      );
    }
  });

  test('clamps intent signal scores to 35', () {
    final signals = AurenIntentSignals.fromIntent(
      'السودان مصر الصين الإمارات كينيا نيجيريا الخرطوم القاهرة دبي شنتشن '
      'رخيص شحن مورد مصنع جملة كميات',
    );
    expect(
      signals.matchScore(
        'السودان مصر الصين الإمارات كينيا نيجيريا الخرطوم القاهرة دبي شنتشن '
        'رخيص شحن مورد مصنع جملة كميات supplier manufacturer wholesale bulk cheap',
      ),
      lessThanOrEqualTo(35),
    );
  });
}

  test('routes Arabic supplier sourcing with quote action', () {
    final plan = AurenIntentActionPlan.fromIntent('عايز مورد سمسم');
    expect(plan.actionFor(AurenMatchKind.business), AurenMatchAction.requestQuote);
  });

  test('routes Spanish supplier request to quote action', () {
    final plan = AurenIntentActionPlan.fromIntent('busco proveedor');
    expect(plan.actionFor(AurenMatchKind.business), AurenMatchAction.requestQuote);
  });

  test('routes French supplier request to quote action', () {
    final plan = AurenIntentActionPlan.fromIntent('je cherche un fournisseur');
    expect(plan.actionFor(AurenMatchKind.business), AurenMatchAction.requestQuote);
  });

  test('routes Portuguese supplier request to quote action', () {
    final plan = AurenIntentActionPlan.fromIntent('quero fornecedor');
    expect(plan.actionFor(AurenMatchKind.business), AurenMatchAction.requestQuote);
  });

  test('routes Turkish supplier request to quote action', () {
    final plan = AurenIntentActionPlan.fromIntent('tedarikçi arıyorum');
    expect(plan.actionFor(AurenMatchKind.business), AurenMatchAction.requestQuote);
  });

  test('routes Swahili supplier request to quote action', () {
    final plan = AurenIntentActionPlan.fromIntent('nahitaji msambazaji');
    expect(plan.actionFor(AurenMatchKind.business), AurenMatchAction.requestQuote);
  });
