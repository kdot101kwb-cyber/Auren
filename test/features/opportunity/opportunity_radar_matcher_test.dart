import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/opportunity/domain/opportunity_radar_matcher.dart';

void main() {
  const matcher = OpportunityRadarMatcher();
  final now = DateTime.utc(2026, 10, 12);

  test('ranks stronger skill and interest matches first with explanations', () {
    final results = matcher.rank(
      profile: const OpportunityProfile(
        skills: {'Flutter', 'Dart'},
        interests: {'technology', 'education'},
        location: 'Khartoum',
        experienceLevel: 'junior',
      ),
      opportunities: [
        RadarOpportunity(
          id: 'strong',
          title: 'Flutter role',
          requiredSkills: {'flutter', 'dart'},
          tags: {'technology'},
          location: 'KHARTOUM',
          experienceLevel: 'Junior',
          publishedAt: now.subtract(const Duration(days: 2)),
        ),
        const RadarOpportunity(
          id: 'weak',
          title: 'Unrelated role',
          requiredSkills: {'accounting'},
          tags: {'finance'},
          location: 'London',
          experienceLevel: 'senior',
        ),
      ],
      now: now,
      minimumScore: 0,
    );

    expect(results, hasLength(2));
    expect(results.first.opportunity.id, 'strong');
    expect(results.first.score, greaterThan(results.last.score));
    expect(results.first.reasons, contains('Location matches'));
    expect(results.first.reasons.any((reason) => reason.startsWith('Skills matched:')), isTrue);
  });

  test('excludes expired items and duplicate IDs', () {
    final results = matcher.rank(
      profile: const OpportunityProfile(skills: {'design'}),
      opportunities: [
        RadarOpportunity(
          id: 'expired',
          title: 'Expired',
          requiredSkills: {'design'},
          expiresAt: now,
        ),
        const RadarOpportunity(
          id: 'same',
          title: 'First copy',
          requiredSkills: {'design'},
        ),
        const RadarOpportunity(
          id: 'same',
          title: 'Duplicate copy',
          requiredSkills: {'design'},
        ),
      ],
      now: now,
    );

    expect(results.map((item) => item.opportunity.id), ['same']);
    expect(results.single.opportunity.title, 'First copy');
  });

  test('supports score threshold, limit, and deterministic tie breaking', () {
    final results = matcher.rank(
      profile: const OpportunityProfile(),
      opportunities: const [
        RadarOpportunity(id: 'b', title: 'B'),
        RadarOpportunity(id: 'a', title: 'A'),
      ],
      now: now,
      minimumScore: 0,
      limit: 1,
    );
    expect(results, hasLength(1));
    expect(results.single.opportunity.id, 'a');
  });

  test('rejects whitespace-padded IDs to prevent duplicate aliases', () { final results = matcher.rank(profile: const OpportunityProfile(skills: {'design'}), opportunities: const [RadarOpportunity(id: ' role ', title: 'Padded', requiredSkills: {'design'}), RadarOpportunity(id: 'role', title: 'Canonical', requiredSkills: {'design'})], now: now); expect(results.map((e) => e.opportunity.id), ['role']); });

  test('rejects invalid score thresholds and negative limits', () {
    expect(
      () => matcher.rank(
        profile: const OpportunityProfile(),
        opportunities: const [],
        now: now,
        minimumScore: 101,
      ),
      throwsArgumentError,
    );
    expect(
      () => matcher.rank(
        profile: const OpportunityProfile(),
        opportunities: const [],
        now: now,
        limit: -1,
      ),
      throwsArgumentError,
    );
  });
}
