import 'package:flutter_test/flutter_test.dart';

import '../core/intent_engine/models/intent_context.dart';
import '../core/intent_engine/models/intent_entity.dart';
import '../core/match_everything/match_everything.dart';
import '../core/match_everything/models/match_candidate.dart';
import '../core/match_everything/models/match_request.dart';
import 'auren_match_everything_service.dart';

class _RecordingCandidateSource implements MatchCandidateSource {
  MatchRequest? request;

  @override
  Future<List<MatchCandidate>> find(MatchRequest value) async {
    request = value;
    return const [
      MatchCandidate(
        id: 'real-firestore-document-id',
        type: MatchCandidateType.supplier,
        title: 'Matched supplier from test source',
        countryCode: 'CN',
        score: .8,
      ),
    ];
  }
}

void main() {
  test('service resolves a China supplier request and returns candidate plan',
      () async {
    final source = _RecordingCandidateSource();
    final service = AurenMatchEverythingService(candidateSource: source);

    final result = await service.match(const IntentContext(
      userId: 'test-user',
      input: 'عايز مورد ملابس من الصين',
      locale: 'ar',
    ));

    expect(result.intent.intentId, 'supplier.find');
    expect(source.request?.query, 'عايز مورد ملابس من الصين');
    expect(source.request?.entities.any(
      (entity) =>
          entity.type == IntentEntityType.country && entity.value == 'CN',
    ), isTrue);
    expect(result.plan.candidateIds, ['real-firestore-document-id']);
    expect(result.plan.actionIds, ['supplier.workflow']);
    expect(result.plan.requiresHumanApproval, isTrue);
  });

  test('ambiguous query does not call candidate source', () async {
    final source = _RecordingCandidateSource();
    final service = AurenMatchEverythingService(candidateSource: source);

    final result = await service.match(const IntentContext(
      userId: 'test-user',
      input: 'xyz',
    ));

    expect(result.plan.candidateIds, isEmpty);
    expect(source.request, isNull);
  });
}
