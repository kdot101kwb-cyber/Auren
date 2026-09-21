enum AurenDeliveryProviderType { sa3i, linkExpress, afrimex, twseel, wdee, manual }

class AurenDeliveryQuote {
  final String providerId;
  final String providerName;
  final String currency;
  final int priceMinor;
  final int? etaMinutes;
  final bool available;

  const AurenDeliveryQuote({
    required this.providerId,
    required this.providerName,
    required this.currency,
    required this.priceMinor,
    this.etaMinutes,
    required this.available,
  });
}

class AurenDeliveryShipment {
  final String providerId;
  final String shipmentId;
  final String? trackingNumber;
  final String status;
  final DateTime? estimatedDeliveryAt;
  final String? trackingUrl;

  const AurenDeliveryShipment({
    required this.providerId,
    required this.shipmentId,
    this.trackingNumber,
    required this.status,
    this.estimatedDeliveryAt,
    this.trackingUrl,
  });
}
