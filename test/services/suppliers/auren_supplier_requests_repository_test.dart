import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/suppliers/auren_supplier_requests_repository.dart';

void main() {
  group('AurenSupplierRequest.fromMap', () {
    test('maps lifecycle status, dispatch state, retries and failure details', () {
      final request = AurenSupplierRequest.fromMap({
        'id': 'request-1',
        'type': 'rfq',
        'status': 'failed',
        'supplierName': 'Example Supplier',
        'product': 'Cotton',
        'retryCount': 5,
        'lastError': 'Provider is not configured',
        'externalDispatch': false,
        'matchFlowId': 'flow-1',
      });

      expect(request.id, 'request-1');
      expect(request.type, 'rfq');
      expect(request.status, 'failed');
      expect(request.supplierName, 'Example Supplier');
      expect(request.product, 'Cotton');
      expect(request.retryCount, 5);
      expect(request.lastError, 'Provider is not configured');
      expect(request.externalDispatch, isFalse);
      expect(request.matchFlowId, 'flow-1');
      expect(request.title, 'Cotton');
    });

    test('uses safe defaults for optional and malformed fields', () {
      final request = AurenSupplierRequest.fromMap({
        'id': 'request-2',
        'retryCount': 'not-a-number',
        'externalDispatch': 'true',
      });

      expect(request.status, 'draft');
      expect(request.type, 'contact');
      expect(request.retryCount, 0);
      expect(request.lastError, isEmpty);
      expect(request.externalDispatch, isFalse);
      expect(request.title, 'طلب تواصل');
    });
  });
}
