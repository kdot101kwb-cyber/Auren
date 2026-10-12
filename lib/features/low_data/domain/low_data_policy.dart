/// Deterministic network-aware delivery policy for AUREN's low-data mode.
///
/// This policy only recommends a delivery profile; callers still decide how
/// to fetch/cache content and must respect platform/network permissions.
enum DataConnection { offline, metered, unmetered, unknown }
enum DataContentKind { text, thumbnail, image, video, audio, liveMedia }
enum DataQuality { minimal, balanced, high }

class DataDeliveryDecision {
  const DataDeliveryDecision({
    required this.allowNetwork,
    required this.allowAutoplay,
    required this.allowPrefetch,
    required this.quality,
    required this.maxBytes,
    required this.reason,
  });

  final bool allowNetwork;
  final bool allowAutoplay;
  final bool allowPrefetch;
  final DataQuality quality;
  final int maxBytes;
  final String reason;
}

class LowDataPolicy {
  const LowDataPolicy();

  DataDeliveryDecision decide({
    required DataConnection connection,
    required DataContentKind content,
    required bool lowDataMode,
    required bool userRequested,
  }) {
    if (connection == DataConnection.offline) {
      return const DataDeliveryDecision(
        allowNetwork: false,
        allowAutoplay: false,
        allowPrefetch: false,
        quality: DataQuality.minimal,
        maxBytes: 0,
        reason: 'Offline: use cached content only',
      );
    }

    final constrained = lowDataMode || connection == DataConnection.metered;
    if (content == DataContentKind.text) {
      return DataDeliveryDecision(
        allowNetwork: true,
        allowAutoplay: false,
        allowPrefetch: !constrained && !userRequested,
        quality: DataQuality.high,
        maxBytes: constrained ? 128 * 1024 : 512 * 1024,
        reason: constrained ? 'Text-first on a limited connection' : 'Text content',
      );
    }

    if (constrained && !userRequested) {
      return const DataDeliveryDecision(
        allowNetwork: false,
        allowAutoplay: false,
        allowPrefetch: false,
        quality: DataQuality.minimal,
        maxBytes: 0,
        reason: 'Wait for explicit user action on a limited connection',
      );
    }

    if (constrained) {
      final isMotion = content == DataContentKind.video ||
          content == DataContentKind.liveMedia ||
          content == DataContentKind.audio;
      return DataDeliveryDecision(
        allowNetwork: true,
        allowAutoplay: false,
        allowPrefetch: false,
        quality: DataQuality.minimal,
        maxBytes: isMotion ? 2 * 1024 * 1024 : 256 * 1024,
        reason: 'User requested content; use data-saving quality',
      );
    }

    return DataDeliveryDecision(
      allowNetwork: true,
      allowAutoplay: !userRequested && content == DataContentKind.video,
      allowPrefetch: !userRequested,
      quality: DataQuality.balanced,
      maxBytes: content == DataContentKind.liveMedia ? 8 * 1024 * 1024 : 4 * 1024 * 1024,
      reason: 'Standard delivery policy',
    );
  }
}
