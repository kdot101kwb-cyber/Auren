import 'auren_ai_provider_catalog.dart';

/// Capability-aware client-side view of the AUREN provider strategy.
/// This list is advisory; the server remains authoritative for provider
/// credentials, health, quotas and actual execution.
class AurenAiProviderRouter {
  static const _capabilityForMode = <String, String>{
    'أغنية': 'music',
    'فيديو': 'video',
    'بودكاست': 'audio',
    'عالم': 'image',
    'قصة': 'image',
  };

  static String capabilityForMode(String mode) =>
      _capabilityForMode[mode.trim()] ?? 'text';

  static List<AurenAiProviderInfo> candidates({
    required String mode,
    bool preferFree = true,
  }) {
    final capability = capabilityForMode(mode);
    final candidates = AurenAiProviderCatalog.enabledFor(capability);
    if (candidates.isEmpty) return const [];

    if (!preferFree) return List.unmodifiable(candidates);

    final ordered = <AurenAiProviderInfo>[];
    for (final tier in const [
      AurenProviderTier.freeFirst,
      AurenProviderTier.freeQuota,
      AurenProviderTier.lowCost,
      AurenProviderTier.premium,
    ]) {
      ordered.addAll(candidates.where((p) => p.tier == tier));
    }
    return List.unmodifiable(ordered);
  }

  static AurenAiProviderInfo? choose({
    required String mode,
    bool preferFree = true,
  }) {
    final items = candidates(mode: mode, preferFree: preferFree);
    return items.isEmpty ? null : items.first;
  }

  static bool canHandle({
    required String providerId,
    required String mode,
  }) {
    final provider = AurenAiProviderCatalog.byId(providerId);
    if (provider == null || !provider.enabled) return false;
    return provider.capabilities.contains(capabilityForMode(mode));
  }
}
