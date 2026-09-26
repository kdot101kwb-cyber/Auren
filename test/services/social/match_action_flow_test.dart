import 'package:flutter_test/flutter_test.dart';

import '../../../lib/services/social/match_action_flow.dart';
import '../../../lib/services/social/match_everything_service.dart';

void main() {
  const business = AurenMatchItem(
    id: 'b1',
    title: 'Supplier',
    subtitle: 'Business',
    kind: AurenMatchKind.business,
    score: 90,
    reasons: [],
    action: AurenMatchAction.requestQuote,
  );

  test('request quote flow exposes requirements and follow-up steps', () {
    final steps = AurenMatchActionFlow().stepsFor(business, 'supplier');
    expect(steps.map((step) => step.id), [
      'find',
      'requirements',
      'contact',
      'follow_up',
    ]);
  });

  test('apply flow exposes submission tracking', () {
    const opportunity = AurenMatchItem(
      id: 'o1',
      title: 'Opportunity',
      subtitle: 'Work',
      kind: AurenMatchKind.opportunity,
      score: 80,
      reasons: [],
      action: AurenMatchAction.apply,
    );
    final steps = AurenMatchActionFlow().stepsFor(opportunity, 'job');
    expect(steps.map((step) => step.id), [
      'find',
      'application',
      'submitted',
      'track',
    ]);
  });

  test('content flow stays lightweight', () {
    const content = AurenMatchItem(
      id: 'c1',
      title: 'Video',
      subtitle: 'Content',
      kind: AurenMatchKind.content,
      score: 75,
      reasons: [],
      action: AurenMatchAction.watch,
    );
    final steps = AurenMatchActionFlow().stepsFor(content, 'watch');
    expect(steps.map((step) => step.id), ['find', 'open']);
  });
}
