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

/// Client-safe orchestration layer. Provider credentials remain server-side.
class AurenEntertainmentJobOrchestrator {
  final EntertainmentRepository repository;
  final AurenEntertainmentProviderRegistry registry;

  AurenEntertainmentJobOrchestrator({
    EntertainmentRepository? repository,
    AurenEntertainmentProviderRegistry? registry,
    AurenEntertainmentProviderStore? providerStore,
  })  : repository = repository ?? EntertainmentRepository(),
        registry = registry ??
            AurenEntertainmentProviderRegistry(
              providers: [AurenPlanningProvider()],
            );

  Future<AurenEntertainmentOrchestratorResult> start(
    String uid,
    String jobId,
  ) async {
    final normalizedUid = uid.trim();
    final normalizedJobId = jobId.trim();
    if (normalizedUid.isEmpty || normalizedJobId.isEmpty) {
      return const AurenEntertainmentOrchestratorResult(
        accepted: false,
        provider: 'none',
        message: 'بيانات المهمة غير مكتملة.',
      );
    }

    final job = await repository.getEntertainmentCreationJob(
      normalizedUid,
      normalizedJobId,
    );
    if (job == null) {
      return const AurenEntertainmentOrchestratorResult(
        accepted: false,
        provider: 'none',
        message: 'مهمة الإنتاج غير موجودة.',
      );
    }

    final status = job['status']?.toString() ?? 'planning';
    final provider = job['provider']?.toString() ?? 'auren_ai';
    if (status == 'ready' || status == 'completed') {
      return AurenEntertainmentOrchestratorResult(
        accepted: true,
        provider: provider,
        message: 'المشروع جاهز بالفعل.',
      );
    }
    if (status == 'generating' ||
        status == 'processing' ||
        status == 'assembling' ||
        status == 'review') {
      return AurenEntertainmentOrchestratorResult(
        accepted: true,
        provider: provider,
        message: 'المهمة قيد التنفيذ بالفعل.',
      );
    }
    if (status == 'cancelled') {
      return const AurenEntertainmentOrchestratorResult(
        accepted: false,
        provider: 'none',
        message: 'المهمة ملغاة. أنشئ مهمة جديدة للمتابعة.',
      );
    }

    // The queue is server-owned; the client only requests a planning state.
    await repository.updateEntertainmentJobStatus(
      normalizedUid,
      normalizedJobId,
      status: 'planning',
      progress: 0,
    );

    return AurenEntertainmentOrchestratorResult(
      accepted: true,
      provider: provider,
      message: 'تمت إعادة المهمة إلى طابور AUREN للتنفيذ.',
    );
  }
}
