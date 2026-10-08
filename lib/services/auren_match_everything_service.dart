import '../core/intent_engine/intent_engine.dart';
import '../core/intent_engine/models/intent_context.dart';
import '../core/intent_engine/models/intent_result.dart';
import '../core/intent_engine/resolver/rule_based_intent_resolver.dart';
import '../core/match_everything/match_everything.dart';
import '../core/match_everything/models/match_plan.dart';
import 'match_everything/firestore_match_candidate_source.dart';

/// Application entry point joining intent resolution to real Firestore-backed
/// candidate retrieval. This plans actions only; it never executes them.
class AurenMatchEverythingService {
  AurenMatchEverythingService({
    IntentEngine? intentEngine,
    MatchCandidateSource? candidateSource,
  })  : _intentEngine = intentEngine ?? IntentEngine(const RuleBasedIntentResolver()),
        _matcher = MatchEverything(
          candidateSource ?? FirestoreMatchCandidateSource(),
        );

  final IntentEngine _intentEngine;
  final MatchEverything _matcher;

  Future<MatchEverythingResult> match(IntentContext context) async {
    final intent = _intentEngine.resolve(context);
    final plan = await _matcher.plan(context, intent);
    return MatchEverythingResult(intent: intent, plan: plan);
  }
}

class MatchEverythingResult {
  const MatchEverythingResult({required this.intent, required this.plan});

  final IntentResult intent;
  final MatchPlan plan;
}
