import 'dart:convert';

import 'package:auren/services/social/community_workbench_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AurenCommunityWorkbenchStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = AurenCommunityWorkbenchStore();
  });

  test('space topic and rules persist locally without changing membership data', () async {
    await store.saveSpaceGuidelines(
      spaceId: 'space-1',
      topic: 'Community garden',
      rules: 'Be kind; share tools.',
    );

    final loaded = await store.readSpaceGuidelines('space-1');
    expect(loaded['topic'], 'Community garden');
    expect(loaded['rules'], 'Be kind; share tools.');
    await store.saveSpaceGuidelines(
      spaceId: 'space-1',
      topic: 'Shared garden',
      rules: 'Return borrowed tools.',
    );
    final updated = await store.readSpaceGuidelines('space-1');
    expect(updated['topic'], 'Shared garden');
    expect(updated['rules'], 'Return borrowed tools.');
    expect(await store.readSpaceGuidelines('missing'), isEmpty);
  });

  test('corrupt local space metadata recovers and can be replaced', () async {
    SharedPreferences.setMockInitialValues({
      'auren.community.space_guidelines.v1': '{not-json',
    });
    final recoveringStore = AurenCommunityWorkbenchStore();
    expect(await recoveringStore.readSpaceGuidelines('space-1'), isEmpty);
    await recoveringStore.saveSpaceGuidelines(
      spaceId: 'space-1',
      topic: 'Recovery',
      rules: 'Use respectful language.',
    );
    expect((await recoveringStore.readSpaceGuidelines('space-1'))['topic'], 'Recovery');
  });

  test('project tasks and milestones calculate bounded local progress', () async {
    final id = await store.createProject(
      title: '  Community garden  ',
      description: 'Plan a shared garden',
      communityId: 'community-1',
    );
    await store.addProjectTask(projectId: id, title: 'Prepare beds', assignee: 'member-a');
    await store.addProjectTask(projectId: id, title: 'Plant seeds');
    await store.addProjectMilestone(projectId: id, title: 'Site ready');

    var project = (await store.listProjects()).single;
    expect(project['title'], 'Community garden');
    expect(store.projectProgress(project), 0);

    final tasks = List<Map<String, dynamic>>.from(project['tasks'] as List);
    await store.setProjectTaskStatus(projectId: id, taskId: tasks.first['id'] as String, status: 'done');
    final milestones = List<Map<String, dynamic>>.from(project['milestones'] as List);
    await store.setMilestoneCompleted(
      projectId: id,
      milestoneId: milestones.single['id'] as String,
      completed: true,
    );

    project = (await store.listProjects()).single;
    expect(store.projectProgress(project), 67);
    await expectLater(
      store.setProjectTaskStatus(projectId: id, taskId: tasks.last['id'] as String, status: 'shipped'),
      throwsArgumentError,
    );
  });

  test('in-progress task status is retained without counting as completed', () async {
    final id = await store.createProject(
      title: 'Status workflow',
      description: '',
      communityId: 'community-1',
    );
    await store.addProjectTask(projectId: id, title: 'Coordinate volunteers');
    final project = (await store.listProjects()).single;
    final taskId = (project['tasks'] as List).single['id'] as String;

    await store.setProjectTaskStatus(
      projectId: id,
      taskId: taskId,
      status: 'doing',
    );

    final updated = (await store.listProjects()).single;
    expect((updated['tasks'] as List).single['status'], 'doing');
    expect(store.projectProgress(updated), 0);
  });

  test('project bounds reject empty names and cap tasks', () async {
    await expectLater(
      store.createProject(title: ' ', description: '', communityId: ''),
      throwsArgumentError,
    );
    final id = await store.createProject(title: 'Small project', description: '', communityId: 'community-1');
    for (var i = 0; i < 100; i++) {
      await store.addProjectTask(projectId: id, title: 'Task $i');
    }
    await expectLater(
      store.addProjectTask(projectId: id, title: 'Overflow task'),
      throwsStateError,
    );
  });

  test('governance proposal records one local vote per voter and closes', () async {
    final id = await store.createRuleProposal(
      communityId: 'community-1',
      title: 'Keep spaces respectful',
      proposedRule: 'No harassment or threats.',
    );
    await store.voteOnProposal(proposalId: id, voterId: 'member-a', support: true);
    await store.voteOnProposal(proposalId: id, voterId: 'member-b', support: false);
    final proposal = (await store.listProposals()).single;
    expect(store.proposalSupportCount(proposal), 1);
    await expectLater(
      store.voteOnProposal(proposalId: id, voterId: 'member-a', support: false),
      throwsStateError,
    );
    await store.closeProposal(proposalId: id, status: 'accepted');
    await expectLater(
      store.voteOnProposal(proposalId: id, voterId: 'member-c', support: true),
      throwsStateError,
    );
  });

  test('meetup is a local draft and attendance never exceeds data-driven state', () async {
    final id = await store.createMeetupDraft(
      title: 'Community clean-up',
      description: 'Bring gloves if available.',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Park (suggested)',
      capacity: 30,
    );
    await store.setDraftAttendance(meetupId: id, attendeeId: 'member-a', status: 'going');
    await store.setDraftAttendance(meetupId: id, attendeeId: 'member-b', status: 'interested');
    final meetup = (await store.listMeetupDrafts()).single;
    expect(meetup['status'], 'draft');
    expect(meetup['capacity'], 30);
    expect(store.meetupGoingCount(meetup), 1);
    expect(meetup['attendance'], containsPair('member-a', 'going'));
    await expectLater(
      store.createMeetupDraft(
        title: 'Invalid event',
        description: '',
        startsAt: 'not-a-date',
        location: '',
        capacity: 0,
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.setDraftAttendance(meetupId: id, attendeeId: 'member-c', status: 'booked'),
      throwsArgumentError,
    );
  });

  test('space metadata, proposals, and meetup drafts remain bounded', () async {
    for (var i = 0; i < 100; i++) {
      await store.saveSpaceGuidelines(
        spaceId: 'space-$i',
        topic: 'Topic $i',
        rules: 'Rule $i',
      );
    }
    await expectLater(
      store.saveSpaceGuidelines(
        spaceId: 'space-100',
        topic: 'Topic 100',
        rules: 'Rule 100',
      ),
      throwsStateError,
    );
    expect((await store.readSpaceGuidelines('space-0'))['topic'], 'Topic 0');
    expect(await store.readSpaceGuidelines('space-100'), isEmpty);

    for (var i = 0; i < 100; i++) {
      await store.createRuleProposal(
        communityId: 'community',
        title: 'Proposal $i',
        proposedRule: 'Rule $i',
      );
      await store.createMeetupDraft(
        title: 'Meetup $i',
        description: '',
        startsAt: '2026-11-01T17:00:00Z',
        location: 'Suggested',
        capacity: 10,
      );
    }
    await expectLater(
      store.createRuleProposal(
        communityId: 'community',
        title: 'Overflow proposal',
        proposedRule: 'Rule overflow',
      ),
      throwsStateError,
    );
    await expectLater(
      store.createMeetupDraft(
        title: 'Overflow meetup',
        description: '',
        startsAt: '2026-11-01T17:00:00Z',
        location: 'Suggested',
        capacity: 10,
      ),
      throwsStateError,
    );
    final proposals = await store.listProposals();
    final meetups = await store.listMeetupDrafts();
    expect(proposals, hasLength(100));
    expect(proposals.map((item) => item['title']), contains('Proposal 0'));
    expect(meetups, hasLength(100));
    expect(meetups.map((item) => item['title']), contains('Meetup 0'));
  });

  test('local persistence survives a new store instance', () async {
    final id = await store.createProject(title: 'Offline plan', description: '', communityId: 'community-1');
    final reloaded = AurenCommunityWorkbenchStore();
    expect((await reloaded.listProjects()).single['id'], id);
  });

  test('local drafts can be deleted without touching remote community records', () async {
    final projectId = await store.createProject(
      title: 'Local project',
      description: '',
      communityId: 'community-1',
    );
    final proposalId = await store.createRuleProposal(
      communityId: 'community-1',
      title: 'Local proposal',
      proposedRule: 'Keep the space safe.',
    );
    final meetupId = await store.createMeetupDraft(
      title: 'Local meetup',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested location',
      capacity: 12,
    );

    await store.deleteProject(projectId);
    await store.deleteProposal(proposalId);
    await store.deleteMeetupDraft(meetupId);

    expect(await store.listProjects(), isEmpty);
    expect(await store.listProposals(), isEmpty);
    expect(await store.listMeetupDrafts(), isEmpty);
    await expectLater(store.deleteProject(projectId), throwsStateError);
    await expectLater(store.deleteProposal(' '), throwsArgumentError);
    await expectLater(store.deleteMeetupDraft(meetupId), throwsStateError);
  });

  test('local attendance list is bounded and existing attendee can update status', () async {
    final meetupId = await store.createMeetupDraft(
      title: 'Bounded meetup',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested',
      capacity: 10000,
    );
    for (var i = 0; i < 1000; i++) {
      await store.setDraftAttendance(
        meetupId: meetupId,
        attendeeId: 'local-$i',
        status: 'interested',
      );
    }
    await store.setDraftAttendance(
      meetupId: meetupId,
      attendeeId: 'local-0',
      status: 'going',
    );
    await expectLater(
      store.setDraftAttendance(
        meetupId: meetupId,
        attendeeId: 'local-overflow',
        status: 'going',
      ),
      throwsStateError,
    );
    final meetup = (await store.listMeetupDrafts()).single;
    expect((meetup['attendance'] as Map).length, 1000);
    expect((meetup['attendance'] as Map)['local-0'], 'going');
  });


  test('corrupt project, proposal and meetup caches recover on the next save', () async {
    SharedPreferences.setMockInitialValues({
      'auren.community.group_projects.v1': '{bad-project-json',
      'auren.community.governance_proposals.v1': '{bad-proposal-json',
      'auren.community.meetup_drafts.v1': '{bad-meetup-json',
    });
    final recoveringStore = AurenCommunityWorkbenchStore();

    expect(await recoveringStore.listProjects(), isEmpty);
    expect(await recoveringStore.listProposals(), isEmpty);
    expect(await recoveringStore.listMeetupDrafts(), isEmpty);

    await recoveringStore.createProject(
      title: 'Recovered project',
      description: '',
      communityId: 'community-1',
    );
    await recoveringStore.createRuleProposal(
      communityId: 'community-1',
      title: 'Recovered proposal',
      proposedRule: 'Be kind.',
    );
    await recoveringStore.createMeetupDraft(
      title: 'Recovered meetup',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested',
      capacity: 10,
    );

    expect((await recoveringStore.listProjects()).single['title'], 'Recovered project');
    expect((await recoveringStore.listProposals()).single['title'], 'Recovered proposal');
    expect((await recoveringStore.listMeetupDrafts()).single['title'], 'Recovered meetup');
  });


  test('project capacity rejects overflow without evicting existing records', () async {
    for (var i = 0; i < 99; i++) {
      await store.createProject(
        title: 'Existing project $i',
        description: '',
        communityId: 'community',
      );
    }

    final attempts = await Future.wait([
      store.createProject(
        title: 'Concurrent project A',
        description: '',
        communityId: 'community',
      ).then<Object?>((id) => id, onError: (Object error) => error),
      store.createProject(
        title: 'Concurrent project B',
        description: '',
        communityId: 'community',
      ).then<Object?>((id) => id, onError: (Object error) => error),
      store.createProject(
        title: 'Concurrent project C',
        description: '',
        communityId: 'community',
      ).then<Object?>((id) => id, onError: (Object error) => error),
    ]);

    expect(attempts.whereType<String>(), hasLength(1));
    expect(attempts.whereType<StateError>(), hasLength(2));
    final projects = await store.listProjects();
    expect(projects, hasLength(100));
    expect(projects.map((item) => item['title']), contains('Existing project 0'));
    expect(
      projects
          .map((item) => item['title'] as String)
          .where((title) => title.startsWith('Concurrent project ')),
      hasLength(1),
    );
  });

  test('valid JSON with invalid record shapes is ignored without crashing', () async {
    SharedPreferences.setMockInitialValues({
      'auren.community.space_guidelines.v1':
          '{"space-bad":{"topic":42,"rules":[],"updatedAt":false}}',
      'auren.community.group_projects.v1':
          '[{"id":7,"title":"bad","tasks":"not-a-list","milestones":[]}]',
      'auren.community.governance_proposals.v1':
          '[{"id":"p","communityId":"c","title":"bad","proposedRule":"rule","votes":[],"status":"open","createdAt":"now"}]',
      'auren.community.meetup_drafts.v1':
          '[{"id":"m","title":"bad","description":"","startsAt":"not-a-date","location":"here","capacity":10,"attendance":{},"status":"draft","createdAt":"now"}]',
    });
    final recoveringStore = AurenCommunityWorkbenchStore();

    expect(await recoveringStore.readSpaceGuidelines('space-bad'), isEmpty);
    expect(await recoveringStore.listProjects(), isEmpty);
    expect(await recoveringStore.listProposals(), isEmpty);
    expect(await recoveringStore.listMeetupDrafts(), isEmpty);

    SharedPreferences.setMockInitialValues({
      'auren.community.group_projects.v1': jsonEncode([
        {
          'id': 'p1',
          'title': List.filled(121, 'x').join(),
          'description': '',
          'communityId': 'c',
          'createdAt': DateTime.utc(2026).toIso8601String(),
          'tasks': [],
          'milestones': [],
        },
      ]),
      'auren.community.governance_proposals.v1': jsonEncode([
        {
          'id': 'proposal-1',
          'communityId': 'c',
          'title': 'Valid title',
          'proposedRule': 'Rule',
          'createdAt': DateTime.utc(2026).toIso8601String(),
          'status': 'open',
          'votes': {List.filled(129, 'v').join(): true},
        },
      ]),
      'auren.community.meetup_drafts.v1': jsonEncode([
        {
          'id': 'meetup-1',
          'title': 'Valid title',
          'description': '',
          'startsAt': DateTime.utc(2026, 11).toIso8601String(),
          'location': 'Somewhere',
          'capacity': 10,
          'attendance': {List.filled(129, 'a').join(): 'going'},
          'status': 'draft',
          'createdAt': DateTime.utc(2026).toIso8601String(),
        },
      ]),
    });
    final boundedStore = AurenCommunityWorkbenchStore();
    expect(await boundedStore.listProjects(), isEmpty);
    expect(await boundedStore.listProposals(), isEmpty);
    expect(await boundedStore.listMeetupDrafts(), isEmpty);

    await recoveringStore.saveSpaceGuidelines(
      spaceId: 'space-good',
      topic: 'Safe cache',
      rules: 'Keep records valid.',
    );
    await recoveringStore.createProject(
      title: 'Valid project',
      description: '',
      communityId: 'community',
    );
    await recoveringStore.createRuleProposal(
      communityId: 'community',
      title: 'Valid proposal',
      proposedRule: 'Be kind.',
    );
    await recoveringStore.createMeetupDraft(
      title: 'Valid meetup',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested',
      capacity: 10,
    );

    expect((await recoveringStore.listProjects()).single['title'], 'Valid project');
    expect((await recoveringStore.listProposals()).single['title'], 'Valid proposal');
    expect((await recoveringStore.listMeetupDrafts()).single['title'], 'Valid meetup');
  });

  test('signed-in account scopes isolate projects, proposals, meetups and space metadata', () async {
    final accountA = AurenCommunityWorkbenchStore(scope: 'uid-a');
    final accountB = AurenCommunityWorkbenchStore(scope: 'uid-b');

    await accountA.saveSpaceGuidelines(
      spaceId: 'space-shared-id',
      topic: 'Private topic A',
      rules: 'Account A rules',
    );
    await accountA.createProject(
      title: 'Account A project',
      description: '',
      communityId: 'community-1',
    );
    await accountA.createRuleProposal(
      communityId: 'community-1',
      title: 'Account A proposal',
      proposedRule: 'Rule A',
    );
    await accountA.createMeetupDraft(
      title: 'Account A meetup',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested',
      capacity: 10,
    );

    expect(await accountB.readSpaceGuidelines('space-shared-id'), isEmpty);
    expect(await accountB.listProjects(), isEmpty);
    expect(await accountB.listProposals(), isEmpty);
    expect(await accountB.listMeetupDrafts(), isEmpty);

    await accountB.createProject(
      title: 'Account B project',
      description: '',
      communityId: 'community-1',
    );
    expect((await accountA.listProjects()).single['title'], 'Account A project');
    expect((await accountB.listProjects()).single['title'], 'Account B project');
  });


  test('concurrent local mutations preserve projects, tasks, proposals and meetups', () async {
    final secondStore = AurenCommunityWorkbenchStore(scope: 'parallel-account');
    final firstStore = AurenCommunityWorkbenchStore(scope: 'parallel-account');

    await Future.wait(List.generate(20, (index) {
      final target = index.isEven ? firstStore : secondStore;
      return target.createProject(
        title: 'Concurrent project $index',
        description: '',
        communityId: 'community-1',
      );
    }));
    expect(await firstStore.listProjects(), hasLength(20));

    final projectId = (await firstStore.listProjects()).first['id'] as String;
    await Future.wait(List.generate(20, (index) {
      final target = index.isEven ? firstStore : secondStore;
      return target.addProjectTask(
        projectId: projectId,
        title: 'Concurrent task $index',
      );
    }));
    final project = (await firstStore.listProjects())
        .singleWhere((item) => item['id'] == projectId);
    expect(project['tasks'], hasLength(20));

    await Future.wait(List.generate(20, (index) {
      final target = index.isEven ? firstStore : secondStore;
      return target.createRuleProposal(
        communityId: 'community-1',
        title: 'Concurrent proposal $index',
        proposedRule: 'Rule $index',
      );
    }));
    expect(await firstStore.listProposals(), hasLength(20));

    await Future.wait(List.generate(20, (index) {
      final target = index.isEven ? firstStore : secondStore;
      return target.createMeetupDraft(
        title: 'Concurrent meetup $index',
        description: '',
        startsAt: '2026-11-01T17:00:00Z',
        location: 'Suggested',
        capacity: 10,
      );
    }));
    expect(await firstStore.listMeetupDrafts(), hasLength(20));
  });

  test('concurrent duplicate votes cannot overwrite or double count', () async {
    final otherStore = AurenCommunityWorkbenchStore();
    final proposalId = await store.createRuleProposal(
      communityId: 'community-1',
      title: 'Vote once',
      proposedRule: 'Be respectful.',
    );

    final results = await Future.wait([
      store.voteOnProposal(
        proposalId: proposalId,
        voterId: 'member-1',
        support: true,
      ).then<Object?>((_) => null, onError: (Object error) => error),
      otherStore.voteOnProposal(
        proposalId: proposalId,
        voterId: 'member-1',
        support: false,
      ).then<Object?>((_) => null, onError: (Object error) => error),
    ]);

    expect(results.whereType<StateError>(), hasLength(1));
    final proposal = (await store.listProposals()).single;
    expect((proposal['votes'] as Map), hasLength(1));
    expect(store.proposalSupportCount(proposal), inInclusiveRange(0, 1));
  });



  test('local drafts are isolated between signed-in account scopes', () async {
    final accountA = AurenCommunityWorkbenchStore(scope: 'account-a');
    final accountB = AurenCommunityWorkbenchStore(scope: 'account-b');

    final projectId = await accountA.createProject(
      title: 'Private account A project',
      description: '',
      communityId: 'community-1',
    );
    await accountA.createRuleProposal(
      communityId: 'community-1',
      title: 'Account A proposal',
      proposedRule: 'Keep the space safe.',
    );
    await accountA.createMeetupDraft(
      title: 'Account A meetup',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested',
      capacity: 10,
    );
    await accountA.saveSpaceGuidelines(
      spaceId: 'space-1',
      topic: 'Account A topic',
      rules: 'Account A rules',
    );

    expect((await accountA.listProjects()).single['id'], projectId);
    expect(await accountB.listProjects(), isEmpty);
    expect(await accountB.listProposals(), isEmpty);
    expect(await accountB.listMeetupDrafts(), isEmpty);
    expect(await accountB.readSpaceGuidelines('space-1'), isEmpty);
  });

  test('concurrent duplicate local votes preserve one-vote invariant', () async {
    final proposalId = await store.createRuleProposal(
      communityId: 'community-1',
      title: 'Concurrent vote',
      proposedRule: 'Be respectful.',
    );

    final results = await Future.wait([
      store.voteOnProposal(
        proposalId: proposalId,
        voterId: 'member-a',
        support: true,
      ).then<Object?>((_) => 'accepted', onError: (Object error) => error),
      store.voteOnProposal(
        proposalId: proposalId,
        voterId: 'member-a',
        support: false,
      ).then<Object?>((_) => 'accepted', onError: (Object error) => error),
    ]);

    expect(results.whereType<String>(), hasLength(1));
    expect(results.whereType<StateError>(), hasLength(1));
    final proposal = (await store.listProposals()).single;
    expect((proposal['votes'] as Map).length, 1);
    expect((proposal['votes'] as Map).containsKey('member-a'), isTrue);
  });

  test('concurrent attendance updates do not overwrite one another', () async {
    final meetupId = await store.createMeetupDraft(
      title: 'Concurrent attendance',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested',
      capacity: 10000,
    );

    await Future.wait([
      store.setDraftAttendance(
        meetupId: meetupId,
        attendeeId: 'member-a',
        status: 'going',
      ),
      store.setDraftAttendance(
        meetupId: meetupId,
        attendeeId: 'member-b',
        status: 'interested',
      ),
      store.setDraftAttendance(
        meetupId: meetupId,
        attendeeId: 'member-c',
        status: 'declined',
      ),
    ]);

    final meetup = (await store.listMeetupDrafts()).single;
    final attendance = Map<String, dynamic>.from(meetup['attendance'] as Map);
    expect(attendance, hasLength(3));
    expect(attendance['member-a'], 'going');
    expect(attendance['member-b'], 'interested');
    expect(attendance['member-c'], 'declined');
    expect(meetup['status'], 'draft');
  });





  test('meetup start times normalize to UTC and invalid dates are rejected', () async {
    final meetupId = await store.createMeetupDraft(
      title: 'Timezone-safe draft',
      description: '',
      startsAt: '2026-11-01T19:30:00+02:00',
      location: 'Suggested only',
      capacity: 1,
    );

    final meetup = (await store.listMeetupDrafts()).single;
    expect(meetup['id'], meetupId);
    expect(meetup['startsAt'], '2026-11-01T17:30:00.000Z');
    expect(meetup['status'], 'draft');

    await expectLater(
      store.createMeetupDraft(
        title: 'Invalid date',
        description: '',
        startsAt: 'not-a-date',
        location: 'Suggested',
        capacity: 1,
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.createMeetupDraft(
        title: 'Invalid capacity',
        description: '',
        startsAt: '2026-11-01T17:00:00Z',
        location: 'Suggested',
        capacity: 10001,
      ),
      throwsArgumentError,
    );
    expect(await store.listMeetupDrafts(), hasLength(1));
  });

  test('attendance status cannot exceed the explicit local state set', () async {
    final meetupId = await store.createMeetupDraft(
      title: 'Bounded attendance states',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested',
      capacity: 5,
    );

    await expectLater(
      store.setDraftAttendance(
        meetupId: meetupId,
        attendeeId: 'member-1',
        status: 'reserved',
      ),
      throwsArgumentError,
    );
    expect((await store.listMeetupDrafts()).single['attendance'], isEmpty);
  });

  test('project creation rejects missing or oversized community identifiers', () async {
    await expectLater(
      store.createProject(
        title: 'Orphan project',
        description: '',
        communityId: '  ',
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.createProject(
        title: 'Oversized community reference',
        description: '',
        communityId: List.filled(161, 'c').join(),
      ),
      throwsArgumentError,
    );
    expect(await store.listProjects(), isEmpty);
  });


  test('local records are isolated between signed-in account scopes', () async {
    final accountA = AurenCommunityWorkbenchStore(scope: 'user-a');
    final accountB = AurenCommunityWorkbenchStore(scope: 'user-b');

    await accountA.createProject(
      title: 'Private A project',
      description: '',
      communityId: 'community-a',
    );
    await accountA.createRuleProposal(
      communityId: 'community-a',
      title: 'A proposal',
      proposedRule: 'A-only rule',
    );
    await accountA.createMeetupDraft(
      title: 'A meetup',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested',
      capacity: 10,
    );

    expect(await accountB.listProjects(), isEmpty);
    expect(await accountB.listProposals(), isEmpty);
    expect(await accountB.listMeetupDrafts(), isEmpty);
    expect((await accountA.listProjects()).single['title'], 'Private A project');
  });

  test('concurrent local task additions do not overwrite each other', () async {
    final id = await store.createProject(
      title: 'Concurrent task plan',
      description: '',
      communityId: 'community',
    );

    await Future.wait([
      for (var i = 0; i < 12; i++)
        store.addProjectTask(projectId: id, title: 'Task $i'),
    ]);

    final project = (await store.listProjects()).single;
    final tasks = List<Map<String, dynamic>>.from(project['tasks'] as List);
    expect(tasks, hasLength(12));
    expect(tasks.map((task) => task['title']).toSet(), hasLength(12));
  });

  test('concurrent votes from one local voter cannot be duplicated', () async {
    final id = await store.createRuleProposal(
      communityId: 'community',
      title: 'One vote',
      proposedRule: 'One local vote per voter.',
    );

    final attempts = await Future.wait([
      store.voteOnProposal(
        proposalId: id,
        voterId: 'same-voter',
        support: true,
      ).then<Object?>((_) => 'saved', onError: (Object error) => error),
      store.voteOnProposal(
        proposalId: id,
        voterId: 'same-voter',
        support: false,
      ).then<Object?>((_) => 'saved', onError: (Object error) => error),
    ]);

    expect(attempts.whereType<String>(), hasLength(1));
    expect(attempts.whereType<StateError>(), hasLength(1));
    final proposal = (await store.listProposals()).single;
    expect((proposal['votes'] as Map).length, 1);
  });

  test('space guideline cache rejects invalid timestamps and caps recovered records', () async {
    final cache = <String, dynamic>{
      'bad-time': {
        'topic': 'Invalid timestamp',
        'rules': 'Should be ignored.',
        'updatedAt': 'not-a-date',
      },
      List.filled(161, 'x').join(): {
        'topic': 'Oversized key',
        'rules': 'Should be ignored.',
        'updatedAt': DateTime.utc(2026).toIso8601String(),
      },
    };
    for (var i = 0; i < 105; i++) {
      cache['space-$i'] = {
        'topic': 'Topic $i',
        'rules': 'Rule $i',
        'updatedAt': DateTime.utc(2026).toIso8601String(),
      };
    }
    SharedPreferences.setMockInitialValues({
      'auren.community.space_guidelines.v1': jsonEncode(cache),
    });

    final recovered = AurenCommunityWorkbenchStore();
    final first = await recovered.readSpaceGuidelines('space-0');
    expect(first['topic'], 'Topic 0');
    expect(await recovered.readSpaceGuidelines('bad-time'), isEmpty);
    expect(await recovered.readSpaceGuidelines(List.filled(161, 'x').join()), isEmpty);

    // Reading an oversized valid JSON cache never returns more than the
    // documented 100 local guideline records.
    var readable = 0;
    for (var i = 0; i < 105; i++) {
      if ((await recovered.readSpaceGuidelines('space-$i')).isNotEmpty) readable++;
    }
    expect(readable, 100);
  });

  test('list caches cap recovered records and ignore duplicate record IDs', () async {
    final proposals = <Map<String, dynamic>>[
      for (var i = 0; i < 105; i++)
        {
          'id': 'proposal-$i',
          'communityId': 'community-1',
          'title': 'Proposal $i',
          'proposedRule': 'Rule $i',
          'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
          'status': 'open',
          'votes': <String, bool>{},
        },
    ];
    // Duplicate identities are ambiguous and must not leak through as
    // separate rows, even if a cache was modified outside this store.
    proposals.insert(1, Map<String, dynamic>.from(proposals.first));
    SharedPreferences.setMockInitialValues({
      'auren.community.governance_proposals.v1': jsonEncode(proposals),
    });

    final recovered = AurenCommunityWorkbenchStore();
    final loaded = await recovered.listProposals();
    expect(loaded, hasLength(100));
    expect(loaded.map((proposal) => proposal['id']).toSet(), hasLength(100));
    expect(loaded.first['id'], 'proposal-0');
  });


  test('concurrent project task writes do not overwrite one another', () async {
    final id = await store.createProject(
      title: 'Concurrent collaboration',
      description: '',
      communityId: 'community-1',
    );

    await Future.wait([
      for (var i = 0; i < 20; i++)
        store.addProjectTask(projectId: id, title: 'Task $i'),
    ]);

    final project = (await store.listProjects()).single;
    final tasks = List<Map<String, dynamic>>.from(project['tasks'] as List);
    expect(tasks, hasLength(20));
    expect(tasks.map((task) => task['title']).toSet(), hasLength(20));
  });

  test('concurrent governance votes keep one vote per local voter', () async {
    final id = await store.createRuleProposal(
      communityId: 'community-1',
      title: 'Protect shared spaces',
      proposedRule: 'Respect other members.',
    );

    await expectLater(
      Future.wait([
        store.voteOnProposal(proposalId: id, voterId: 'member-a', support: true),
        store.voteOnProposal(proposalId: id, voterId: 'member-a', support: false),
      ]),
      throwsStateError,
    );

    final proposal = (await store.listProposals()).single;
    final votes = Map<String, bool>.from(proposal['votes'] as Map);
    expect(votes, hasLength(1));
    expect(votes.containsKey('member-a'), isTrue);
  });

  test('meetup draft capacity limits local going intentions but allows changes', () async {
    final id = await store.createMeetupDraft(
      title: 'Small planning meetup',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested location',
      capacity: 1,
    );

    await store.setDraftAttendance(
      meetupId: id,
      attendeeId: 'member-a',
      status: 'going',
    );
    await expectLater(
      store.setDraftAttendance(
        meetupId: id,
        attendeeId: 'member-b',
        status: 'going',
      ),
      throwsStateError,
    );

    // A participant may revise their local intention; the capacity limit
    // must not trap a person in the "going" state.
    await store.setDraftAttendance(
      meetupId: id,
      attendeeId: 'member-a',
      status: 'interested',
    );
    await store.setDraftAttendance(
      meetupId: id,
      attendeeId: 'member-b',
      status: 'going',
    );

    final meetup = (await store.listMeetupDrafts()).single;
    expect(store.meetupGoingCount(meetup), 1);
    expect(meetup['attendance'], containsPair('member-a', 'interested'));
    expect(meetup['attendance'], containsPair('member-b', 'going'));
  });

  test('community workspace records are isolated by account scope', () async {
    final firstAccount = AurenCommunityWorkbenchStore(scope: 'account-a');
    final secondAccount = AurenCommunityWorkbenchStore(scope: 'account-b');

    await firstAccount.saveSpaceGuidelines(
      spaceId: 'space-shared-id',
      topic: 'Account A topic',
      rules: 'Private local notes A',
    );
    await firstAccount.createProject(
      title: 'Account A project',
      description: '',
      communityId: 'community-1',
    );
    await firstAccount.createRuleProposal(
      communityId: 'community-1',
      title: 'Account A proposal',
      proposedRule: 'Rule A',
    );
    await firstAccount.createMeetupDraft(
      title: 'Account A meetup',
      description: '',
      startsAt: '2026-11-01T17:00:00Z',
      location: 'Suggested',
      capacity: 10,
    );

    expect(
      (await secondAccount.readSpaceGuidelines('space-shared-id')),
      isEmpty,
    );
    expect(await secondAccount.listProjects(), isEmpty);
    expect(await secondAccount.listProposals(), isEmpty);
    expect(await secondAccount.listMeetupDrafts(), isEmpty);
  });


  test('closed local proposals reject votes and normalized voter IDs cannot vote twice', () async {
    final id = await store.createRuleProposal(
      communityId: 'community-1',
      title: 'Local governance lifecycle',
      proposedRule: 'A closed draft cannot accept new votes.',
    );

    await store.voteOnProposal(
      proposalId: id,
      voterId: ' member-a ',
      support: true,
    );
    await expectLater(
      store.voteOnProposal(
        proposalId: id,
        voterId: 'member-a',
        support: false,
      ),
      throwsStateError,
    );

    await store.closeProposal(proposalId: id, status: 'accepted');
    await expectLater(
      store.voteOnProposal(
        proposalId: id,
        voterId: 'member-b',
        support: true,
      ),
      throwsStateError,
    );

    final proposal = (await store.listProposals()).single;
    expect(proposal['status'], 'accepted');
    expect(proposal['votes'], containsPair('member-a', true));
    expect((proposal['votes'] as Map), hasLength(1));
  });

  test('local governance rejects blank and oversized voter identities', () async {
    final id = await store.createRuleProposal(
      communityId: 'community-1',
      title: 'Bound voter identity',
      proposedRule: 'Voter identifiers have a strict local bound.',
    );

    await expectLater(
      store.voteOnProposal(proposalId: id, voterId: '   ', support: true),
      throwsArgumentError,
    );
    await expectLater(
      store.voteOnProposal(
        proposalId: id,
        voterId: List.filled(129, 'v').join(),
        support: true,
      ),
      throwsArgumentError,
    );

    expect((await store.listProposals()).single['votes'], isEmpty);
  });


  test('concurrent local vote and closure preserve a valid proposal lifecycle', () async {
    final id = await store.createRuleProposal(
      communityId: 'community-1',
      title: 'Concurrent close and vote',
      proposedRule: 'Closure and voting are serialized locally.',
    );

    final outcomes = await Future.wait<Object?>([
      store.voteOnProposal(
        proposalId: id,
        voterId: 'member-a',
        support: true,
      ).then<Object?>((_) => 'vote-saved', onError: (Object error) => error),
      store.closeProposal(
        proposalId: id,
        status: 'accepted',
      ).then<Object?>((_) => 'closed', onError: (Object error) => error),
    ]);

    expect(outcomes.whereType<String>().length, inInclusiveRange(1, 2));
    expect(outcomes.whereType<StateError>().length, lessThanOrEqualTo(1));
    final proposal = (await store.listProposals()).single;
    expect(proposal['status'], 'accepted');
    final votes = Map<String, bool>.from(proposal['votes'] as Map);
    expect(votes.length, lessThanOrEqualTo(1));
    if (votes.isNotEmpty) {
      expect(votes, containsPair('member-a', true));
    }
  });


  test('separate store instances serialize writes for the same account scope', () async {
    final first = AurenCommunityWorkbenchStore(scope: 'shared-account');
    final second = AurenCommunityWorkbenchStore(scope: 'shared-account');
    final projectId = await first.createProject(
      title: 'Cross-instance local writes',
      description: '',
      communityId: 'community-1',
    );

    await Future.wait([
      for (var i = 0; i < 10; i++)
        (i.isEven ? first : second).addProjectTask(
          projectId: projectId,
          title: 'Task $i',
        ),
    ]);

    final project = (await second.listProjects()).single;
    final tasks = List<Map<String, dynamic>>.from(project['tasks'] as List);
    expect(tasks, hasLength(10));
    expect(tasks.map((task) => task['title']).toSet(), hasLength(10));
  });

}
