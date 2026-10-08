import '../intent_engine/models/intent_context.dart';
import '../intent_engine/models/intent_entity.dart';
import '../intent_engine/models/intent_result.dart';
import 'models/match_request.dart';
import 'models/match_candidate.dart';
import 'models/match_plan.dart';

abstract class MatchCandidateSource {
  Future<List<MatchCandidate>> find(MatchRequest request);
}

class MatchEverything {
  final MatchCandidateSource source;

  const MatchEverything(this.source);

  Future<MatchPlan> plan(IntentContext context, IntentResult intent) async {
    if (intent.ambiguous || intent.candidateActionIds.isEmpty) {
      return MatchPlan(intentId: intent.intentId);
    }

    final entities = intent.entities.whereType<IntentEntity>().toList();
    final request = MatchRequest(
      userId: context.userId,
      query: context.input,
      countryCode: context.countryCode,
      currencyCode: context.currencyCode,
      entities: entities,
    );

    final candidates = await source.find(request);

    return MatchPlan(
      intentId: intent.intentId,
      candidateIds: candidates.map((candidate) => candidate.id).toList(),
      actionIds: intent.candidateActionIds,
      requiresHumanApproval: true,
    );
  }
}
