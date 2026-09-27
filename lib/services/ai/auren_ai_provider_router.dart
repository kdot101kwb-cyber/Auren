import 'auren_ai_provider_catalog.dart';

enum AurenAiTask { chat, planning, summarization, translation, vision, imageGeneration, videoGeneration, speech, music }

/// Capability-aware client-side view of the AUREN provider strategy.
/// This list is advisory; the server remains authoritative for provider
/// credentials, health, quotas and actual execution.
class AurenAiProviderRouter {
  static const _capabilityForTask = <AurenAiTask, String>{
    AurenAiTask.chat: 'text',
    AurenAiTask.planning: 'text',
    AurenAiTask.summarization: 'text',
    AurenAiTask.translation: 'text',
    AurenAiTask.vision: 'vision',
    AurenAiTask.imageGeneration: 'image',
    AurenAiTask.videoGeneration: 'video',
    AurenAiTask.speech: 'audio',
    AurenAiTask.music: 'music',
  };

  static const _capabilityForMode = <String, String>{
    'أغنية': 'music',
    'فيديو': 'video',
    'بودكاست': 'audio',
    'عالم': 'image',
    'قصة': 'image',
  };

  static String capabilityForTask(AurenAiTask task) =>
      _capabilityForTask[task] ?? 'text';

  static String capabilityForMode(String mode) =>
      _capabilityForMode[mode.trim()] ?? 'text';

  static List<AurenAiProviderInfo> candidatesForTask({
    required AurenAiTask task,
    bool preferFree = true,
  }) => candidatesForCapability(
        capability: capabilityForTask(task),
        preferFree: preferFree,
      );

  static List<AurenAiProviderInfo> candidates({
    required String mode,
    bool preferFree = true,
  }) => candidatesForCapability(
        capability: capabilityForMode(mode),
        preferFree: preferFree,
      );

  static List<AurenAiProviderInfo> candidatesForCapability({
    required String capability,
    bool preferFree = true,
  }) {
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

  static AurenAiProviderInfo? chooseForTask({
    required AurenAiTask task,
    bool preferFree = true,
  }) {
    final items = candidatesForTask(task: task, preferFree: preferFree);
    return items.isEmpty ? null : items.first;
  }

  static AurenAiProviderInfo? choose({
    required String mode,
    bool preferFree = true,
  }) {
    final items = candidates(mode: mode, preferFree: preferFree);
    return items.isEmpty ? null : items.first;
  }

  static bool canHandleTask({
    required String providerId,
    required AurenAiTask task,
  }) {
    final provider = AurenAiProviderCatalog.byId(providerId);
    if (provider == null || !provider.enabled) return false;
    return provider.capabilities.contains(capabilityForTask(task));
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
