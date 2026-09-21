import '../../core/models/delivery.dart';

abstract class AurenDeliveryProvider {
  String get id;
  String get displayName;

  Future<AurenDeliveryQuote?> quote({
    required String pickupAddress,
    required String deliveryAddress,
    required int packageWeightGrams,
    required String currency,
  });

  Future<AurenDeliveryShipment> createShipment({
    required String orderId,
    required String pickupAddress,
    required String deliveryAddress,
    required String recipientName,
    required String recipientPhone,
    required int packageWeightGrams,
    required String currency,
  });

  Future<AurenDeliveryShipment?> track(String trackingNumber);
}

class AurenDeliveryGateway {
  final List<AurenDeliveryProvider> providers;

  const AurenDeliveryGateway({this.providers = const [AurenManualDeliveryProvider()]});

  Future<List<AurenDeliveryQuote>> getQuotes({
    required String pickupAddress,
    required String deliveryAddress,
    required int packageWeightGrams,
    required String currency,
  }) async {
    final results = <AurenDeliveryQuote>[];
    for (final provider in providers) {
      try {
        final quote = await provider.quote(
          pickupAddress: pickupAddress,
          deliveryAddress: deliveryAddress,
          packageWeightGrams: packageWeightGrams,
          currency: currency,
        );
        if (quote != null && quote.available) results.add(quote);
      } catch (_) {
        // One unavailable provider must not break the whole marketplace.
      }
    }
    results.sort((a, b) => a.priceMinor.compareTo(b.priceMinor));
    return results;
  }

  Future<AurenDeliveryShipment> createShipment({
    required AurenDeliveryProvider provider,
    required String orderId,
    required String pickupAddress,
    required String deliveryAddress,
    required String recipientName,
    required String recipientPhone,
    required int packageWeightGrams,
    required String currency,
  }) {
    return provider.createShipment(
      orderId: orderId,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      packageWeightGrams: packageWeightGrams,
      currency: currency,
    );
  }
}

/// Manual provider is the safe fallback until a courier API contract is connected.
class AurenManualDeliveryProvider implements AurenDeliveryProvider {
  const AurenManualDeliveryProvider();

  @override
  String get id => AurenDeliveryProviders.manual;

  @override
  String get displayName => 'توصيل يدوي';

  @override
  Future<AurenDeliveryQuote?> quote({
    required String pickupAddress,
    required String deliveryAddress,
    required int packageWeightGrams,
    required String currency,
  }) async {
    return const AurenDeliveryQuote(
      providerId: AurenDeliveryProviders.manual,
      providerName: 'توصيل يدوي',
      currency: 'USD',
      priceMinor: 0,
      etaMinutes: null,
      available: true,
    );
  }

  @override
  Future<AurenDeliveryShipment> createShipment({
    required String orderId,
    required String pickupAddress,
    required String deliveryAddress,
    required String recipientName,
    required String recipientPhone,
    required int packageWeightGrams,
    required String currency,
  }) async {
    return AurenDeliveryShipment(
      providerId: id,
      shipmentId: 'manual-$orderId',
      status: 'pending',
      estimatedDeliveryAt: null,
      trackingUrl: null,
    );
  }

  @override
  Future<AurenDeliveryShipment?> track(String trackingNumber) async => null;
}

/// Providers saved for partnership/integration work after AUREN launch.
class AurenDeliveryProviders {
  static const sa3i = 'sa3i';
  static const linkExpress = 'link_express';
  static const afrimex = 'afrimex';
  static const twseel = 'twseel';
  static const wdee = 'wdee';
  static const manual = 'manual';

  static String displayName(String id) {
    switch (id) {
      case sa3i: return 'Sa3i';
      case linkExpress: return 'Link Express';
      case afrimex: return 'Afrimex';
      case twseel: return 'Twseel';
      case wdee: return 'Wdee';
      default: return 'توصيل يدوي';
    }
  }
}
