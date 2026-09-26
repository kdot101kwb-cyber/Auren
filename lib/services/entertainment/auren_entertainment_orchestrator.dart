import 'entertainment_providers.dart';
import 'entertainment_repository.dart';

class AurenEntertainmentOrchestratorResult {
  final bool accepted;
  final String provider;
  final String message;

  const AurenEntertainmentOrchestratorResult({
    required this.accepted,
    required this.provider,
    required this.message,
  });
}

/// Client-safe orchestration layer.
///
/// It resolves a provider, builds a generation request, and persists only
/// auditable provider metadata. Real provider credentials must remain server-side.
class AurenEntertainmentJobOrchestrator {
  final EntertainmentRepository repository;
  final AurenEntertainmentProviderRegistry registry;
  final AurenEntertainmentProviderStore providerStore;

  AurenEntertainmentJobOrchestrator({
    EntertainmentRepository? repository,
    AurenEntertainmentProviderRegistry? registry,
    AurenEntertainmentProviderStore? providerStore,
  })  : repository = repository ?? EntertainmentRepository(),
        registry = registry ?? AurenEntertainmentProviderRegistry(
          providers: const [AurenPlanningProvider()],
        ),
        providerStore = providerStore ?? AurenEntertainmentProviderStore();

  Future<AurenEntertainmentOrchestratorResult> start(
    String uid,
    String jobId,
  ) async {
    if (uid.isEmpty || jobId.isEmpty) {
      return const AurenEntertainmentOrchestratorResult(
        accepted: false,
        provider: 'none',
        message: 'بيانات المهمة غير مكتملة.',
      );
    }

    final job = await repository.getEntertainmentCreationJob(uid, jobId);
    if (job == null) {
      return const AurenEntertainmentOrchestratorResult(
        accepted: false,
        provider: 'none',
        message: 'مهمة الإنتاج غير موجودة.',
      );
    }

    final status = job['status']?.toString() ?? 'planning';
    if (status == 'cancelled') {
      return const AurenEntertainmentOrchestratorResult(
        accepted: false,
        provider: 'none',
        message: 'المهمة ملغاة. أعد المحاولة أولاً.',
      );
    }
    if (status == 'ready') {
      return AurenEntertainmentOrchestratorResult(
        accepted: true,
        provider: job['provider']?.toString() ?? 'unknown',
        message: 'المشروع جاهز بالفعل.',
      );
    }
    if (status == 'generating' || status == 'processing') {
      return AurenEntertainmentOrchestratorResult(
        accepted: true,
        provider: job['provider']?.toString() ?? 'unknown',
        message: 'المهمة قيد التنفيذ بالفعل.',
      );
    }

    final provider = registry.forMode(job['mode']?.toString() ?? '');
    if (provider == null) {
      return const AurenEntertainmentOrchestratorResult(
        accepted: false,
        provider: 'none',
        message: 'لا يوجد مزوّد متاح لهذا النوع حالياً.',
      );
    }

    final request = AurenGenerationRequest(
      jobId: jobId,
      mode: job['mode']?.toString() ?? '',
      mood: job['mood']?.toString() ?? '',
      length: job['length']?.toString() ?? '',
      idea: job['idea']?.toString() ?? '',
      plan: _stringList(job['plan']),
      assets: _stringList(job['assets']),
    );

    final generation = await provider.submit(request);
    await providerStore.recordSubmission(
      uid,
      jobId,
      provider: generation.provider,
      externalJobId: generation.externalJobId,
    );

    if (!generation.accepted) {
      await repository.updateEntertainmentJobStatus(
        uid,
        jobId,
        status: 'planning',
        progress: 0,
      );
      return AurenEntertainmentOrchestratorResult(
        accepted: false,
        provider: generation.provider,
        message: generation.message,
      );
    }

    await repository.updateEntertainmentJobStatus(
      uid,
      jobId,
      status: 'generating',
      progress: 1,
    );

    return AurenEntertainmentOrchestratorResult(
      accepted: true,
      provider: generation.provider,
      message: generation.message,
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
