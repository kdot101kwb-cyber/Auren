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

  const AurenDeliveryGateway({this.providers = const []});

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

/// Providers saved for partnership/integration work after AUREN launch.
class AurenDeliveryProviders {
  static const sa3i = 'sa3i';
  static const linkExpress = 'link_express';
  static const afrimex = 'afrimex';
  static const twseel = 'twseel';
  static const wdee = 'wdee';
}
