class AurenPaymentIntent {
  final String id;
  final String method;
  final String status;
  final int amountMinor;
  final String currency;

  const AurenPaymentIntent({
    required this.id,
    required this.method,
    required this.status,
    required this.amountMinor,
    required this.currency,
  });
}

abstract class AurenPaymentProvider {
  String get id;
  String get displayName;

  Future<AurenPaymentIntent> createIntent({
    required String orderId,
    required int amountMinor,
    required String currency,
  });
}

class AurenCashOnDeliveryProvider implements AurenPaymentProvider {
  @override
  String get id => 'cash_on_delivery';

  @override
  String get displayName => 'الدفع عند الاستلام';

  @override
  Future<AurenPaymentIntent> createIntent({
    required String orderId,
    required int amountMinor,
    required String currency,
  }) async {
    return AurenPaymentIntent(
      id: 'cod-$orderId',
      method: id,
      status: 'unpaid',
      amountMinor: amountMinor,
      currency: currency,
    );
  }
}

/// Online providers plug into this interface once AUREN has a merchant
/// contract/API. No fake charge is performed by the MVP.
class AurenPendingOnlinePaymentProvider implements AurenPaymentProvider {
  @override
  String get id => 'pending_gateway';

  @override
  String get displayName => 'دفع إلكتروني';

  @override
  Future<AurenPaymentIntent> createIntent({
    required String orderId,
    required int amountMinor,
    required String currency,
  }) async {
    return AurenPaymentIntent(
      id: 'pending-$orderId',
      method: id,
      status: 'pending',
      amountMinor: amountMinor,
      currency: currency,
    );
  }
}
