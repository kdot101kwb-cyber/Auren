import 'package:flutter_test/flutter_test.dart';

import '../intent_engine/models/intent_context.dart';
import '../intent_engine/models/intent_entity.dart';
import '../intent_engine/models/intent_result.dart';
import 'match_everything.dart';
import 'models/match_candidate.dart';
import 'models/match_request.dart';

class _FakeSource implements MatchCandidateSource {
  MatchRequest? lastRequest;

  @override
  Future<List<MatchCandidate>> find(MatchRequest request) async {
    lastRequest = request;
    return const [
      MatchCandidate(
        id: 'supplier-sd-1',
        type: MatchCandidateType.supplier,
        title: 'Example supplier',
        countryCode: 'SD',
        score: .91,
      ),
      MatchCandidate(
        id: 'supplier-cn-1',
        type: MatchCandidateType.supplier,
        title: 'Example China supplier',
        countryCode: 'CN',
        score: .89,
      ),
    ];
  }
}

void main() {
  test('Match Everything passes global country context to candidate source', () async {
    final source = _FakeSource();
    const matcher = MatchEverything(source);

    final plan = await matcher.plan(
      const IntentContext(
        userId: 'user',
        input: 'عايز مورد ملابس في السودان',
        locale: 'ar',
        countryCode: 'SD',
        currencyCode: 'SDG',
      ),
      IntentResult(
        intentId: 'supplier.find',
        confidence: .94,
        candidateActionIds: ['supplier.workflow'],
        entities: [
          IntentEntity(
            type: IntentEntityType.country,
            value: 'SD',
          ),
        ],
      ),
    );

    expect(source.lastRequest?.countryCode, 'SD');
    expect(source.lastRequest?.currencyCode, 'SDG');
    expect(plan.candidateIds, ['supplier-sd-1', 'supplier-cn-1']);
    expect(plan.actionIds, ['supplier.workflow']);
    expect(plan.requiresHumanApproval, isTrue);
  });

  test('ambiguous intent never performs candidate matching', () async {
    final source = _FakeSource();
    const matcher = MatchEverything(source);

    final plan = await matcher.plan(
      const IntentContext(userId: 'user', input: 'something unclear'),
      IntentResult(
        intentId: 'unknown',
        confidence: .2,
        candidateActionIds: [],
        ambiguous: true,
      ),
    );

    expect(source.lastRequest, isNull);
    expect(plan.candidateIds, isEmpty);
    expect(plan.actionIds, isEmpty);
  });
}
