import '../../features/entertainment/models/auren_production_models.dart';

class AurenProductionEngineRouter {
  const AurenProductionEngineRouter();

  AurenVideoEngine select({
    required AurenProductionType type,
    required int targetMinutes,
  }) {
    if (type == AurenProductionType.short) {
      return AurenVideoEngine.moneyPrinterTurbo;
    }
    if (targetMinutes >= 30) {
      return AurenVideoEngine.skyReelsV3;
    }
    return AurenVideoEngine.ltx2;
  }

  Map<String, dynamic> buildWorkerPayload({
    required String jobId,
    required AurenProductionType type,
    required int targetMinutes,
    required AurenVideoEngine engine,
    String storyBible = '',
    String script = '',
    List<Map<String, dynamic>> shots = const [],
  }) => {
    'jobId': jobId,
    'type': type.name,
    'targetMinutes': targetMinutes,
    'engine': engine.name,
    'storyBible': storyBible,
    'script': script,
    'shots': shots,
  };
}
