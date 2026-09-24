import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/actions/action_registry.dart';

void main() {
  test('registry requires exact payload keys', () {
    expect(
      AurenActionRegistry.isPayloadAllowed('demo.create_note', {'text': 'hello'}),
      isTrue,
    );
    expect(
      AurenActionRegistry.isPayloadAllowed('demo.create_note', {'text': 'hello', 'extra': true}),
      isFalse,
    );
    expect(
      AurenActionRegistry.isPayloadAllowed('memory.save', {'key': 'name'}),
      isFalse,
    );
    expect(
      AurenActionRegistry.isPayloadAllowed('memory.save', {'key': 'name', 'value': 'Khalid'}),
      isTrue,
    );
  });

  test('registry rejects non-canonical action types', () {
    expect(
      AurenActionRegistry.isPayloadAllowed(' DEMO.ECHO ', {'text': 'hello'}),
      isFalse,
    );
    expect(AurenActionRegistry.get('demo.echo'), isNotNull);
  });
}
