import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/global_directory/domain/supplier_rfq_intent_parser.dart';

void main() {
  group('SupplierRfqIntentParser', () {
    test('extracts English request fields', () {
      final r = SupplierRfqIntentParser.parse(
        'I need 500 cotton shirts delivered to Khartoum, Sudan with a budget of \$1200 within 14 days',
      );
      // No unit was supplied, so keep the quantity unit-free instead of guessing.
      expect(r.quantity, '500');
      expect(r.unit, isNull);
      expect(r.destination, 'Khartoum, Sudan');
      expect(r.budget, '1200');
      expect(r.currency, 'USD');
      expect(r.leadTime, '14 days');
      expect(r.product, contains('cotton shirts'));
      expect(r.missingRequiredFields, isEmpty);
    });

    test('normalizes Arabic digits and extracts Arabic fields', () {
      final r = SupplierRfqIntentParser.parse(
        'أحتاج ٥٠٠ قطعة قماش إلى الخرطوم بميزانية ١٢٠٠ دولار',
      );
      expect(r.quantity, '500 pieces');
      expect(r.destination, 'الخرطوم');
      expect(r.budget, '1200');
      expect(r.currency, 'USD');
      expect(r.product, contains('قماش'));
    });

    test('reports missing required fields', () {
      final r = SupplierRfqIntentParser.parse('I need cotton shirts');
      expect(r.product, 'cotton shirts');
      expect(r.missingRequiredFields, containsAll(['الكمية', 'وجهة التسليم']));
    });

    test('does not invent details for vague input', () {
      final r = SupplierRfqIntentParser.parse('hello');
      expect(r.product, isNull);
      expect(r.quantity, isNull);
      expect(r.destination, isNull);
      expect(r.budget, isNull);
      expect(r.missingRequiredFields, hasLength(3));
    });

    test('prefers labeled quantity over product model numbers', () {
      final r = SupplierRfqIntentParser.parse(
        'I need iPhone 15, quantity 20 boxes delivered to Nairobi with a budget of USD 4500 within 14 days',
      );
      expect(r.quantity, '20 boxes');
      expect(r.product, contains('iPhone 15'));
      expect(r.budget, '4500');
      expect(r.leadTime, '14 days');
    });

    test('does not infer quantity from a product model number alone', () {
      final r = SupplierRfqIntentParser.parse(
        'I need iPhone 15 delivered to Nairobi with a budget of USD 4500',
      );
      expect(r.quantity, isNull);
      expect(r.product, contains('iPhone 15'));
      expect(r.budget, '4500');
    });

    test('does not mistake an earlier budget or later lead time for quantity', () {
      final r = SupplierRfqIntentParser.parse(
        'Budget USD 4500; I need 500 cotton shirts delivered to Khartoum within 14 days',
      );
      expect(r.quantity, '500');
      expect(r.budget, '4500');
      expect(r.leadTime, '14 days');
      expect(r.destination, 'Khartoum');
    });

    test('does not treat a natural-language budget as quantity', () {
      final r = SupplierRfqIntentParser.parse(
        'Please source cotton fabric with a budget of USD 4500',
      );
      expect(r.quantity, isNull);
      expect(r.budget, '4500');
      expect(r.currency, 'USD');
    });

    test('supports Arabic explicit quantity labels after a budget', () {
      final r = SupplierRfqIntentParser.parse(
        'ميزانية ١٢٠٠ دولار، الكمية: ٥٠٠ قطعة قماش إلى الخرطوم',
      );
      expect(r.quantity, '500 pieces');
      expect(r.budget, '1200');
      expect(r.destination, 'الخرطوم');
    });

    test('does not infer a quantity from lead time alone', () {
      final r = SupplierRfqIntentParser.parse(
        'I need iPhone 15 delivered within 14 days',
      );
      expect(r.quantity, isNull);
      expect(r.leadTime, '14 days');
    });

    test('supports currency codes without conversion', () {
      final r = SupplierRfqIntentParser.parse(
        'need 20 boxes of tea to Nairobi budget KES 4500',
      );
      expect(r.currency, 'KES');
      expect(r.budget, '4500');
    });
  });
}
