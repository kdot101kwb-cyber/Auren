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

  AurenEntertainmentJobOrchestrator({
    EntertainmentRepository? repository,
    AurenEntertainmentProviderRegistry? registry,
    AurenEntertainmentProviderStore? providerStore,
  })  : repository = repository ?? EntertainmentRepository(),
        registry = registry ?? AurenEntertainmentProviderRegistry(
          providers: const [AurenPlanningProvider()],
        ),

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

    // The queue is server-owned. The client only asks for a fresh planning
    // state; the Cloud Functions lifecycle re-queues and dispatches it.
    await repository.updateEntertainmentJobStatus(
      uid,
      jobId,
      status: 'planning',
      progress: 0,
    );

    return AurenEntertainmentOrchestratorResult(
      accepted: true,
      provider: job['provider']?.toString() ?? 'auren_ai',
      message: 'تمت إعادة المهمة إلى طابور AUREN للتنفيذ.',
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
