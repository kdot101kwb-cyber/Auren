import 'auren_ai_provider_catalog.dart';

/// Chooses only providers that are actually enabled in AUREN's server adapters.
/// Free-first is a preference, not a promise of unlimited free usage.
class AurenAiProviderRouter {
  static const _capabilityForMode = <String, String>{
    'أغنية': 'music',
    'فيديو': 'video',
    'بودكاست': 'audio',
    'عالم': 'image',
    'قصة': 'image',
  };

  static AurenAiProviderInfo? choose({
    required String mode,
    bool preferFree = true,
  }) {
    final capability = _capabilityForMode[mode] ?? 'text';
    final candidates = AurenAiProviderCatalog.enabledFor(capability);
    if (candidates.isEmpty) return null;

    if (preferFree) {
      for (final tier in const [
        AurenProviderTier.freeFirst,
        AurenProviderTier.freeQuota,
        AurenProviderTier.lowCost,
        AurenProviderTier.premium,
      ]) {
        for (final provider in candidates) {
          if (provider.tier == tier) return provider;
        }
      }
    }
    return candidates.first;
  }
}
