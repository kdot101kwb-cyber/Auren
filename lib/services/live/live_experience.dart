enum LiveSessionType {
  normal,
  hybrid,
}

enum LiveVibe {
  hangout,
  music,
  gaming,
  create,
  proveSkill,
  justLive,
}

enum LiveInteractionType {
  comment,
  reaction,
  voiceSnippet,
  question,
  endorsement,
  challenge,
  microOffer,
  toolingSupport,
  gift,
}

enum LiveGiftEffect {
  none,
  funnyMic,
  pinQuestion,
  openMic,
  environment,
}

class LiveVibeOption {
  final LiveVibe vibe;
  final LiveSessionType sessionType;
  final bool suggestsSkillLayer;

  const LiveVibeOption({
    required this.vibe,
    required this.sessionType,
    required this.suggestsSkillLayer,
  });
}

const liveVibeOptions = <LiveVibeOption>[
  LiveVibeOption(vibe: LiveVibe.hangout, sessionType: LiveSessionType.normal, suggestsSkillLayer: false),
  LiveVibeOption(vibe: LiveVibe.music, sessionType: LiveSessionType.normal, suggestsSkillLayer: true),
  LiveVibeOption(vibe: LiveVibe.gaming, sessionType: LiveSessionType.normal, suggestsSkillLayer: false),
  LiveVibeOption(vibe: LiveVibe.create, sessionType: LiveSessionType.hybrid, suggestsSkillLayer: true),
  LiveVibeOption(vibe: LiveVibe.proveSkill, sessionType: LiveSessionType.hybrid, suggestsSkillLayer: true),
  LiveVibeOption(vibe: LiveVibe.justLive, sessionType: LiveSessionType.normal, suggestsSkillLayer: false),
];

class LiveQuestion {
  final String id;
  final String authorId;
  final String text;
  final int votes;
  final bool pinned;
  final DateTime createdAt;

  const LiveQuestion({
    required this.id,
    required this.authorId,
    required this.text,
    this.votes = 0,
    this.pinned = false,
    required this.createdAt,
  });

  LiveQuestion copyWith({int? votes, bool? pinned}) => LiveQuestion(
        id: id,
        authorId: authorId,
        text: text,
        votes: votes ?? this.votes,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt,
      );
}

class LiveHighlight {
  final String id;
  final String segmentId;
  final String label;
  final Duration start;
  final Duration end;

  const LiveHighlight({
    required this.id,
    required this.segmentId,
    required this.label,
    required this.start,
    required this.end,
  });
}

class LiveEndorsement {
  final String id;
  final String endorserId;
  final String skillId;
  final String segmentId;
  final DateTime createdAt;

  const LiveEndorsement({
    required this.id,
    required this.endorserId,
    required this.skillId,
    required this.segmentId,
    required this.createdAt,
  });
}

class LiveChallenge {
  final String id;
  final String challengerId;
  final String prompt;
  final Duration duration;
  final String segmentId;
  final DateTime createdAt;

  const LiveChallenge({
    required this.id,
    required this.challengerId,
    required this.prompt,
    required this.duration,
    required this.segmentId,
    required this.createdAt,
  });
}

class LiveMicroOffer {
  final String id;
  final String senderId;
  final String recipientId;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;

  const LiveMicroOffer({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.title,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
  });
}

class LiveSentimentSnapshot {
  final DateTime createdAt;
  final double positive;
  final double curious;
  final double neutral;

  const LiveSentimentSnapshot({
    required this.createdAt,
    required this.positive,
    required this.curious,
    required this.neutral,
  });
}

class LiveProofSummary {
  final String segmentId;
  final String skillId;
  final double proofScore;
  final double confidence;
  final List<String> evidenceIds;
  final DateTime createdAt;

  const LiveProofSummary({
    required this.segmentId,
    required this.skillId,
    required this.proofScore,
    required this.confidence,
    this.evidenceIds = const [],
    required this.createdAt,
  });
}
