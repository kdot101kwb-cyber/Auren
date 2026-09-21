import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/marketplace/auren_payment_gateway.dart';
import 'package:auren/services/marketplace/auren_delivery_gateway.dart';

void main() {
  group('AUREN payment state machine', () {
    test('allows valid payment transitions', () {
      expect(AurenPaymentStateMachine.canTransition('unpaid', 'pending'), isTrue);
      expect(AurenPaymentStateMachine.canTransition('pending', 'paid'), isTrue);
      expect(AurenPaymentStateMachine.canTransition('paid', 'refunded'), isTrue);
    });

    test('rejects invalid payment transitions', () {
      expect(AurenPaymentStateMachine.canTransition('refunded', 'paid'), isFalse);
      expect(AurenPaymentStateMachine.canTransition('paid', 'pending'), isFalse);
      expect(AurenPaymentStateMachine.canTransition('pending', 'refunded'), isFalse);
    });
  });

  group('AUREN delivery state machine', () {
    test('allows the normal delivery lifecycle', () {
      expect(AurenDeliveryStateMachine.canTransition('pending', 'assigned'), isTrue);
      expect(AurenDeliveryStateMachine.canTransition('assigned', 'picked_up'), isTrue);
      expect(AurenDeliveryStateMachine.canTransition('picked_up', 'shipped'), isTrue);
      expect(AurenDeliveryStateMachine.canTransition('shipped', 'delivered'), isTrue);
    });

    test('allows delivery failure and return paths', () {
      expect(AurenDeliveryStateMachine.canTransition('shipped', 'failed'), isTrue);
      expect(AurenDeliveryStateMachine.canTransition('failed', 'returned'), isTrue);
      expect(AurenDeliveryStateMachine.canTransition('shipped', 'returned'), isTrue);
    });

    test('rejects invalid delivery transitions', () {
      expect(AurenDeliveryStateMachine.canTransition('delivered', 'assigned'), isFalse);
      expect(AurenDeliveryStateMachine.canTransition('pending', 'delivered'), isFalse);
      expect(AurenDeliveryStateMachine.canTransition('returned', 'shipped'), isFalse);
    });
  });
}
