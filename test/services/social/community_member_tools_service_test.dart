import 'package:auren/services/social/community_member_tools_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('onboarding checklist persists completion per community', () async {
    final service = AurenCommunityMemberToolsService();
    final initial = await service.onboardingTasks('garden');
    expect(initial, hasLength(4));
    expect(initial.every((task) => !task.completed), isTrue);

    await service.setOnboardingTask(
      communityId: 'garden', taskId: 'read_guidelines', completed: true);
    final saved = await service.onboardingTasks('garden');
    expect(saved.first.completed, isTrue);
    expect((await service.onboardingTasks('book-club')).first.completed, isFalse);
  });

  test('resource library validates web links and supports deletion', () async {
    final service = AurenCommunityMemberToolsService();
    await expectLater(service.addResource(communityId: 'garden',
      title: 'Unsafe', link: 'javascript:alert(1)'), throwsArgumentError);
    final id = await service.addResource(communityId: 'garden',
      title: 'Planting guide', link: 'https://example.org/guide',
      description: 'Seasonal planting notes');
    var items = await service.resources('garden');
    expect(items, hasLength(1));
    expect(items.single.title, 'Planting guide');
    expect(items.single.link, 'https://example.org/guide');
    await service.removeResource(communityId: 'garden', resourceId: id);
    items = await service.resources('garden');
    expect(items, isEmpty);
  });

  test('digest preferences persist and invalid frequency falls back safely', () async {
    final service = AurenCommunityMemberToolsService();
    const preferences = AurenCommunityDigestPreferences(
      enabled: true, includeMemory: false, includeResources: true,
      frequency: 'daily');
    await service.saveDigestPreferences(preferences);
    final loaded = await service.digestPreferences();
    expect(loaded.enabled, isTrue);
    expect(loaded.includeMemory, isFalse);
    expect(loaded.frequency, 'daily');

    final malformed = AurenCommunityDigestPreferences.fromMap({
      'enabled': true, 'frequency': 'instant'});
    expect(malformed.frequency, 'weekly');
  });

  test('activity insights only count actions recorded locally', () async {
    final service = AurenCommunityMemberToolsService();
    await service.setOnboardingTask(communityId: 'garden',
      taskId: 'introduce_yourself', completed: true);
    await service.addResource(communityId: 'garden',
      title: 'Community charter', link: 'https://example.org/charter');
    final summary = await service.activitySummary('garden');
    expect(summary.onboardingTasksCompleted, 1);
    expect(summary.resourcesSaved, 1);
    expect(summary.recordedActions, 2);
    expect((await service.activitySummary('other')).recordedActions, 0);
  });

  test('invalid community and unknown onboarding task are rejected', () async {
    final service = AurenCommunityMemberToolsService();
    await expectLater(service.onboardingTasks(' '), throwsArgumentError);
    await expectLater(service.setOnboardingTask(communityId: 'garden',
      taskId: 'not-a-task', completed: true), throwsStateError);
  });
}
