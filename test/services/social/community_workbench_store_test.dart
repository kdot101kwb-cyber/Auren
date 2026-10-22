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

  test('project bounds reject empty names and cap tasks', () async {
    await expectLater(
      store.createProject(title: ' ', description: '', communityId: ''),
      throwsArgumentError,
    );
    final id = await store.createProject(title: 'Small project', description: '', communityId: '');
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
    for (var i = 0; i < 101; i++) {
      await store.saveSpaceGuidelines(
        spaceId: 'space-$i',
        topic: 'Topic $i',
        rules: 'Rule $i',
      );
    }
    expect(await store.readSpaceGuidelines('space-0'), isEmpty);
    expect((await store.readSpaceGuidelines('space-100'))['topic'], 'Topic 100');

    for (var i = 0; i < 101; i++) {
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
    final proposals = await store.listProposals();
    final meetups = await store.listMeetupDrafts();
    expect(proposals, hasLength(100));
    expect(proposals.first['title'], 'Proposal 100');
    expect(meetups, hasLength(100));
    expect(meetups.first['title'], 'Meetup 100');
  });

  test('local persistence survives a new store instance', () async {
    final id = await store.createProject(title: 'Offline plan', description: '', communityId: '');
    final reloaded = AurenCommunityWorkbenchStore();
    expect((await reloaded.listProjects()).single['id'], id);
  });
}
