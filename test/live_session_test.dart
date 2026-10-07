import 'package:flutter_test/flutter_test.dart';

import 'package:auren/services/live/live_session.dart';

void main() {
  test('live session keeps normal and skill segments in one session', () {
    final started = DateTime.utc(2026, 10, 7, 12);
    final segment = LiveSkillSegment(
      id: 'segment-1',
      mode: LiveMode.skill,
      skillId: 'flutter',
      startedAt: started,
      endedAt: started.add(const Duration(minutes: 5)),
    );

    final session = LiveSession(
      id: 'session-1',
      ownerId: 'owner-1',
      title: 'Build with me',
      type: LiveSessionType.hybrid,
      currentMode: LiveMode.normal,
      status: LiveSessionStatus.live,
      createdAt: started,
      segments: [segment],
    );

    final roundTrip = LiveSession.fromMap(
      session.id,
      session.toMap(),
    );

    expect(roundTrip.type, LiveSessionType.hybrid);
    expect(roundTrip.currentMode, LiveMode.normal);
    expect(roundTrip.segments, hasLength(1));
    expect(roundTrip.segments.single.mode, LiveMode.skill);
    expect(roundTrip.segments.single.skillId, 'flutter');
  });

  test('open skill segment is detectable', () {
    final segment = LiveSkillSegment(
      id: 'segment-2',
      mode: LiveMode.skill,
      skillId: 'music',
      startedAt: DateTime.utc(2026, 10, 7),
    );

    expect(segment.isOpen, isTrue);
  });
}
