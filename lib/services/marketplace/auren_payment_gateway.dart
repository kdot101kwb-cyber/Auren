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

class AurenPaymentStateMachine {
  static const states = {'unpaid', 'pending', 'paid', 'failed', 'refunded'};
  static bool canTransition(String from, String to) {
    if (!states.contains(from) || !states.contains(to)) return false;
    if (from == to) return true;
    const transitions = <String, Set<String>>{
      'unpaid': {'pending', 'paid', 'failed'},
      'pending': {'paid', 'failed'},
      'paid': {'refunded'},
      'failed': {'pending'},
      'refunded': <String>{},
    };
    return transitions[from]?.contains(to) ?? false;
  }
}

class AurenPaymentGateway {
  final List<AurenPaymentProvider> providers;

  AurenPaymentGateway({
    List<AurenPaymentProvider>? providers,
  }) : providers = providers ?? [
    AurenCashOnDeliveryProvider(),
    AurenPendingOnlinePaymentProvider(),
  ];

  AurenPaymentProvider? providerFor(String method) {
    for (final provider in providers) {
      if (provider.id == method) return provider;
    }
    return null;
  }

  Future<AurenPaymentIntent> createIntent({
    required String method,
    required String orderId,
    required int amountMinor,
    required String currency,
  }) async {
    if (amountMinor < 0) throw ArgumentError('مبلغ دفع غير صالح');
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw ArgumentError('عملة غير صالحة');
    }
    final provider = providerFor(method);
    if (provider == null) throw ArgumentError('طريقة دفع غير مدعومة');
    return provider.createIntent(
      orderId: orderId,
      amountMinor: amountMinor,
      currency: currency,
    );
  }
}
