import 'package:cloud_firestore/cloud_firestore.dart';

enum AurenCreationCapability {
  music,
  video,
  voice,
  image,
  podcast,
  world,
}

class AurenGenerationRequest {
  final String jobId;
  final String mode;
  final String mood;
  final String length;
  final String idea;
  final List<String> plan;
  final List<String> assets;

  const AurenGenerationRequest({
    required this.jobId,
    required this.mode,
    required this.mood,
    required this.length,
    required this.idea,
    required this.plan,
    required this.assets,
  });
}

class AurenGenerationResult {
  final bool accepted;
  final String provider;
  final String? externalJobId;
  final String message;

  const AurenGenerationResult({
    required this.accepted,
    required this.provider,
    this.externalJobId,
    required this.message,
  });
}

/// Provider contract. Implementations may call a real generation service later.
/// This base layer deliberately does not fabricate media or claim generation happened.
abstract class AurenEntertainmentProvider {
  String get id;
  Set<AurenCreationCapability> get capabilities;

  Future<AurenGenerationResult> submit(AurenGenerationRequest request);
  Future<void> cancel(String externalJobId);
}

class AurenPlanningProvider implements AurenEntertainmentProvider {
  @override
  String get id => 'auren_ai';

  @override
  Set<AurenCreationCapability> get capabilities => AurenCreationCapability.values.toSet();

  @override
  Future<AurenGenerationResult> submit(AurenGenerationRequest request) async {
    return const AurenGenerationResult(
      accepted: false,
      provider: 'auren_ai',
      message: 'الخطة جاهزة، لكن لم يتم ربط مزوّد توليد وسائط حقيقي بعد.',
    );
  }

  @override
  Future<void> cancel(String externalJobId) async {}
}

class AurenEntertainmentProviderRegistry {
  final Map<String, AurenEntertainmentProvider> _providers;

  AurenEntertainmentProviderRegistry({
    Iterable<AurenEntertainmentProvider> providers = const [],
  }) : _providers = {
          for (final provider in providers) provider.id: provider,
        };

  AurenEntertainmentProvider? get(String id) => _providers[id];

  AurenEntertainmentProvider? forMode(String mode) {
    final capability = switch (mode) {
      'أغنية' => AurenCreationCapability.music,
      'فيديو' => AurenCreationCapability.video,
      'بودكاست' => AurenCreationCapability.podcast,
      'عالم' => AurenCreationCapability.world,
      _ => AurenCreationCapability.voice,
    };

    for (final provider in _providers.values) {
      if (provider.capabilities.contains(capability)) return provider;
    }
    return null;
  }

  void register(AurenEntertainmentProvider provider) {
    _providers[provider.id] = provider;
  }

  List<String> get providerIds => _providers.keys.toList(growable: false);
}

/// Small Firestore adapter used by the pipeline to keep provider metadata auditable.
class AurenEntertainmentProviderStore {
  final FirebaseFirestore db;
  AurenEntertainmentProviderStore({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  Future<void> recordSubmission(
    String uid,
    String jobId, {
    required String provider,
    String? externalJobId,
  }) {
    return db.collection('users').doc(uid)
        .collection('entertainmentCreationJobs').doc(jobId).update({
      'provider': provider,
      if (externalJobId != null && externalJobId.isNotEmpty)
        'externalJobId': externalJobId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
