import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/core/approval/nova_owner_action_queue.dart';

void main() {
  late SharedPreferences prefs;
  late NovaOwnerActionQueue queue;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    queue = NovaOwnerActionQueue(preferences: prefs);
  });

  test('read-only local work can be queued as approved without external effects', () async {
    expect(await queue.enqueue(
      id: 'read-1',
      actionType: 'inspect',
      summary: 'Inspect local project status',
      isReadOnly: true,
    ), isTrue);
    final record = (await queue.list()).single;
    expect(record.status, NovaActionStatus.approved);
    expect(record.requiresOwnerApproval, isFalse);
  });

  test('external or sensitive work always waits for owner approval', () async {
    await queue.enqueue(
      id: 'publish-1',
      actionType: 'publish',
      summary: 'Publish exact approved post',
      isReadOnly: true,
      externalSideEffect: true,
    );
    await queue.enqueue(
      id: 'wallet-1',
      actionType: 'wallet',
      summary: 'Change payout destination',
      isReadOnly: false,
      sensitive: true,
    );
    final records = await queue.list();
    expect(records.map((r) => r.status),
        everyElement(NovaActionStatus.awaitingApproval));
    expect(records.every((r) => r.requiresOwnerApproval), isTrue);
  });

  test('approval requires an explicit owner confirmation', () async {
    await queue.enqueue(
      id: 'deploy-1',
      actionType: 'deploy',
      summary: 'Deploy service',
      isReadOnly: false,
    );
    expect(await queue.approve('deploy-1', ownerConfirmed: false), isFalse);
    expect((await queue.list()).single.status,
        NovaActionStatus.awaitingApproval);
    expect(await queue.approve('deploy-1', ownerConfirmed: true), isTrue);
    expect((await queue.list()).single.status, NovaActionStatus.approved);
  });

  test('rejected actions cannot be executed or re-approved', () async {
    await queue.enqueue(
      id: 'send-1',
      actionType: 'send',
      summary: 'Send a message',
      isReadOnly: false,
    );
    expect(await queue.reject('send-1', reason: 'Not approved'), isTrue);
    expect(await queue.claimForExecution('send-1'), isFalse);
    expect(await queue.approve('send-1', ownerConfirmed: true), isFalse);
    expect((await queue.list()).single.status, NovaActionStatus.rejected);
  });

  test('only approved actions can be claimed and completed', () async {
    await queue.enqueue(
      id: 'post-1',
      actionType: 'publish',
      summary: 'Publish post',
      isReadOnly: false,
    );
    expect(await queue.claimForExecution('post-1'), isFalse);
    await queue.approve('post-1', ownerConfirmed: true);
    expect(await queue.claimForExecution('post-1'), isTrue);
    expect(await queue.finish('post-1', success: true), isTrue);
    expect((await queue.list()).single.status, NovaActionStatus.completed);
    expect(await queue.claimForExecution('post-1'), isFalse);
  });

  test('failed execution remains terminal and records completion time', () async {
    await queue.enqueue(
      id: 'task-1',
      actionType: 'build',
      summary: 'Run a build',
      isReadOnly: false,
    );
    await queue.approve('task-1', ownerConfirmed: true);
    await queue.claimForExecution('task-1');
    expect(await queue.finish('task-1', success: false), isTrue);
    final record = (await queue.list()).single;
    expect(record.status, NovaActionStatus.failed);
    expect(record.completedAt, isNotNull);
  });

  test('duplicate IDs and empty fields are rejected', () async {
    expect(await queue.enqueue(
      id: '',
      actionType: 'inspect',
      summary: 'Invalid',
      isReadOnly: true,
    ), isFalse);
    await queue.enqueue(
      id: 'same',
      actionType: 'inspect',
      summary: 'First',
      isReadOnly: true,
    );
    expect(await queue.enqueue(
      id: 'same',
      actionType: 'inspect',
      summary: 'Duplicate',
      isReadOnly: true,
    ), isFalse);
  });
}
