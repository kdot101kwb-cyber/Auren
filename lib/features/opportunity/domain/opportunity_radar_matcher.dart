/// Explainable, deterministic matching for the AUREN Opportunity Radar.
///
/// This layer is intentionally pure Dart: it does not fetch opportunities,
/// contact providers, or execute applications. Callers remain responsible for
/// consent, visibility rules, and any action requiring user approval.
class OpportunityProfile {
  const OpportunityProfile({
    this.skills = const <String>{},
    this.interests = const <String>{},
    this.location,
    this.experienceLevel,
  });

  final Set<String> skills;
  final Set<String> interests;
  final String? location;
  final String? experienceLevel;
}

class RadarOpportunity {
  const RadarOpportunity({
    required this.id,
    required this.title,
    this.requiredSkills = const <String>{},
    this.tags = const <String>{},
    this.location,
    this.experienceLevel,
    this.publishedAt,
    this.expiresAt,
  });

  final String id;
  final String title;
  final Set<String> requiredSkills;
  final Set<String> tags;
  final String? location;
  final String? experienceLevel;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
}

class OpportunityMatch {
  const OpportunityMatch({
    required this.opportunity,
    required this.score,
    required this.reasons,
  });

  final RadarOpportunity opportunity;

  /// A normalized score from 0 to 100.
  final int score;

  /// Human-readable reasons explaining why this item matched.
  final List<String> reasons;
}

class OpportunityRadarMatcher {
  const OpportunityRadarMatcher();

  List<OpportunityMatch> rank({
    required OpportunityProfile profile,
    required Iterable<RadarOpportunity> opportunities,
    required DateTime now,
    int minimumScore = 1,
    int limit = 20,
  }) {
    if (minimumScore < 0 || minimumScore > 100) {
      throw ArgumentError.value(minimumScore, 'minimumScore', 'Must be 0..100');
    }
    if (limit < 0) {
      throw ArgumentError.value(limit, 'limit', 'Must not be negative');
    }

    final seenIds = <String>{};
    final matches = <OpportunityMatch>[];
    for (final opportunity in opportunities) {
      if (opportunity.id.trim().isEmpty || !seenIds.add(opportunity.id)) {
        continue;
      }
      if (opportunity.expiresAt != null &&
          !opportunity.expiresAt!.isAfter(now)) {
        continue;
      }

      final result = _score(profile, opportunity, now);
      if (result.score >= minimumScore) matches.add(result);
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final aDate = a.opportunity.publishedAt;
      final bDate = b.opportunity.publishedAt;
      if (aDate != null && bDate != null) {
        final byDate = bDate.compareTo(aDate);
        if (byDate != 0) return byDate;
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }
      return a.opportunity.id.compareTo(b.opportunity.id);
    });

    if (matches.length <= limit) return List.unmodifiable(matches);
    return List.unmodifiable(matches.take(limit));
  }

  OpportunityMatch _score(
    OpportunityProfile profile,
    RadarOpportunity opportunity,
    DateTime now,
  ) {
    var points = 0;
    final reasons = <String>[];
    final userSkills = _normalize(profile.skills);
    final requiredSkills = _normalize(opportunity.requiredSkills);
    if (requiredSkills.isNotEmpty) {
      final matched = requiredSkills.intersection(userSkills);
      final ratio = matched.length / requiredSkills.length;
      points += (ratio * 40).round();
      if (matched.isNotEmpty) {
        reasons.add('Skills matched: ${matched.toList()..sort()}');
      }
    }

    final interests = _normalize(profile.interests);
    final tags = _normalize(opportunity.tags);
    final matchedTags = interests.intersection(tags);
    if (interests.isNotEmpty && tags.isNotEmpty) {
      points += ((matchedTags.length / tags.length) * 20).round();
      if (matchedTags.isNotEmpty) {
        reasons.add('Interests matched: ${matchedTags.toList()..sort()}');
      }
    }

    final userLocation = _key(profile.location);
    final targetLocation = _key(opportunity.location);
    if (userLocation.isNotEmpty &&
        targetLocation.isNotEmpty &&
        userLocation == targetLocation) {
      points += 15;
      reasons.add('Location matches');
    } else if (targetLocation.isEmpty) {
      points += 5;
      reasons.add('Remote or location-flexible');
    }

    final level = _key(profile.experienceLevel);
    final requiredLevel = _key(opportunity.experienceLevel);
    if (level.isNotEmpty && requiredLevel.isNotEmpty && level == requiredLevel) {
      points += 15;
      reasons.add('Experience level matches');
    }

    final publishedAt = opportunity.publishedAt;
    if (publishedAt != null && !publishedAt.isAfter(now)) {
      final age = now.difference(publishedAt);
      if (age <= const Duration(days: 7)) {
        points += 10;
        reasons.add('Recently published');
      } else if (age <= const Duration(days: 30)) {
        points += 5;
        reasons.add('Published in the last 30 days');
      }
    }

    return OpportunityMatch(
      opportunity: opportunity,
      score: points.clamp(0, 100),
      reasons: List.unmodifiable(reasons),
    );
  }

  Set<String> _normalize(Set<String> values) =>
      values.map(_key).where((value) => value.isNotEmpty).toSet();

  String _key(String? value) => value?.trim().toLowerCase() ?? '';
}
