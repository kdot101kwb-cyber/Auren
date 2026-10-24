import 'dart:convert';

import 'package:auren/services/social/community_workbench_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('malformed cached voter IDs with surrounding whitespace are rejected', () async {
    SharedPreferences.setMockInitialValues({
      'auren.community.governance_proposals.v1': jsonEncode([
        {
          'id': 'proposal-1',
          'communityId': 'community-1',
          'title': 'Respect spaces',
          'proposedRule': 'Keep shared spaces respectful.',
          'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
          'status': 'open',
          'votes': {' member-a ': true},
        },
      ]),
    });

    final store = AurenCommunityWorkbenchStore();
    expect(await store.listProposals(), isEmpty);
  });

  test('malformed cached attendance IDs with surrounding whitespace are rejected', () async {
    SharedPreferences.setMockInitialValues({
      'auren.community.meetup_drafts.v1': jsonEncode([
        {
          'id': 'meetup-1',
          'title': 'Planning meetup',
          'description': '',
          'startsAt': DateTime.utc(2026, 11, 1, 17).toIso8601String(),
          'location': 'Suggested location',
          'capacity': 10,
          'attendance': {' member-a ': 'going'},
          'status': 'draft',
          'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        },
      ]),
    });

    final store = AurenCommunityWorkbenchStore();
    expect(await store.listMeetupDrafts(), isEmpty);
  });

  test('normalized vote and attendance IDs remain valid', () async {
    final store = AurenCommunityWorkbenchStore();
    final proposalId = await store.createRuleProposal(
      communityId: 'community-1',
      title: 'A valid proposal',
      proposedRule: 'Use normalized identifiers.',
    );
    await store.voteOnProposal(
      proposalId: proposalId,
      voterId: ' member-a ',
      support: true,
    );
    final proposal = (await store.listProposals()).single;
    expect(proposal['votes'], containsPair('member-a', true));

    final meetupId = await store.createMeetupDraft(
      title: 'A valid meetup',
      description: '',
      startsAt: DateTime.utc(2026, 11, 1, 17).toIso8601String(),
      location: 'Suggested location',
      capacity: 10,
    );
    await store.setDraftAttendance(
      meetupId: meetupId,
      attendeeId: ' member-a ',
      status: 'going',
    );
    final meetup = (await store.listMeetupDrafts()).single;
    expect(meetup['attendance'], containsPair('member-a', 'going'));
  });
}
