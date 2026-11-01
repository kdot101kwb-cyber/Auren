import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/core/audit/nova_local_audit_ledger.dart';

void main() {
  late SharedPreferences prefs;
  late NovaLocalAuditLedger ledger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    ledger = NovaLocalAuditLedger(preferences: prefs);
  });

  test('appends events and reads them after creating a new ledger', () async {
    expect(await ledger.append(
      id: 'event-1',
      type: 'approval',
      message: 'Owner approved a proposed action',
      actionId: 'action-1',
      metadata: {'surface': 'social'},
    ), isTrue);
    final reopened = NovaLocalAuditLedger(preferences: prefs);
    final events = await reopened.read();
    expect(events, hasLength(1));
    expect(events.single.actionId, 'action-1');
    expect(events.single.metadata['surface'], 'social');
  });

  test('redacts sensitive metadata recursively', () async {
    await ledger.append(
      id: 'event-2',
      type: 'diagnostic',
      message: 'Credential check',
      metadata: {
        'api_key': 'should-not-survive',
        'nested': {
          'wallet_seed_phrase': 'also-secret',
          'safe_label': 'android',
        },
        'authorization': 'Bearer hidden',
      },
    );
    final stored = jsonDecode(prefs.getString('nova.audit.events.v1')!) as List;
    final metadata = stored.single['metadata'] as Map;
    expect(metadata['api_key'], '[redacted]');
    expect(metadata['authorization'], '[redacted]');
    expect((metadata['nested'] as Map)['wallet_seed_phrase'], '[redacted]');
    expect((metadata['nested'] as Map)['safe_label'], 'android');
    expect(jsonEncode(stored), isNot(contains('should-not-survive')));
    expect(jsonEncode(stored), isNot(contains('also-secret')));
  });

  test('duplicate IDs and blank events are rejected', () async {
    expect(await ledger.append(id: '', type: 'x', message: 'y'), isFalse);
    await ledger.append(id: 'same', type: 'x', message: 'first');
    expect(await ledger.append(id: 'same', type: 'x', message: 'second'), isFalse);
  });

  test('limits event history to configured maximum', () async {
    final small = NovaLocalAuditLedger(preferences: prefs, maxEvents: 2);
    await small.append(id: 'one', type: 'task', message: 'one');
    await small.append(id: 'two', type: 'task', message: 'two');
    await small.append(id: 'three', type: 'task', message: 'three');
    expect(await small.read(), hasLength(2));
  });

  test('malformed stored data is recovered as an empty ledger', () async {
    await prefs.setString('nova.audit.events.v1', 'broken-json');
    expect(await ledger.read(), isEmpty);
  });
}
