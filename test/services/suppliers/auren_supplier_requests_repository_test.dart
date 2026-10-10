import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/suppliers/auren_supplier_requests_repository.dart';

void main() {
  group('AurenSupplierRequest.fromMap', () {
    test('parses a complete RFQ request without losing lifecycle metadata', () {
      final request = AurenSupplierRequest.fromMap({
        'id': 'req-42',
        'type': 'rfq',
        'status': 'waiting_response',
        'supplierName': 'Nile Textiles',
        'supplierId': 'supplier-7',
        'product': 'Cotton fabric',
        'quantity': '500 metres',
        'message': 'Please quote delivery to Port Sudan.',
        'currency': 'USD',
        'matchFlowId': 'flow-9',
        'lastError': '',
        'externalDispatch': true,
        'retryCount': 2,
      });

      expect(request.id, 'req-42');
      expect(request.type, 'rfq');
      expect(request.status, 'waiting_response');
      expect(request.supplierName, 'Nile Textiles');
      expect(request.supplierId, 'supplier-7');
      expect(request.product, 'Cotton fabric');
      expect(request.quantity, '500 metres');
      expect(request.message, 'Please quote delivery to Port Sudan.');
      expect(request.currency, 'USD');
      expect(request.matchFlowId, 'flow-9');
      expect(request.externalDispatch, isTrue);
      expect(request.retryCount, 2);
      expect(request.title, 'Cotton fabric');
    });

    test('uses safe defaults for missing or malformed optional fields', () {
      final request = AurenSupplierRequest.fromMap({
        'id': 12,
        'retryCount': 'not-a-number',
        'externalDispatch': 'true',
      });

      expect(request.id, '12');
      expect(request.type, 'contact');
      expect(request.status, 'draft');
      expect(request.supplierName, isEmpty);
      expect(request.retryCount, 0);
      // Dispatch is true only for a real boolean, not a string supplied by data.
      expect(request.externalDispatch, isFalse);
      expect(request.title, 'طلب تواصل');
    });

    test('uses supplier ID when supplier name is absent', () {
      final request = AurenSupplierRequest.fromMap({
        'supplierId': 'supplier-19',
        'type': 'contact',
      });

      expect(request.supplierName, 'supplier-19');
      expect(request.title, 'طلب تواصل');
    });

    test('uses the RFQ fallback title when product is absent', () {
      final request = AurenSupplierRequest.fromMap({
        'type': 'rfq',
        'product': '',
      });

      expect(request.title, 'طلب عرض سعر');
    });

    test('does not treat a malformed retry count as a retry allowance', () {
      final request = AurenSupplierRequest.fromMap({
        'retryCount': -3,
      });

      // Parsing preserves the backend value; enforcement of the retry cap
      // remains the responsibility of the trusted backend.
      expect(request.retryCount, -3);
    });
  });
}
