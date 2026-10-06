/// Music-specific AI capabilities for AUREN Talent.
///
/// This is a talent specialization, not a music entertainment or jobs system.
/// It supports singers, instrumentalists, songwriters, composers, producers and DJs.
class AurenMusicTalentCapability {
  final String id;
  final String name;
  final String description;

  const AurenMusicTalentCapability({
    required this.id,
    required this.name,
    required this.description,
  });
}

class AurenMusicTalentCatalog {
  static const all = <AurenMusicTalentCapability>[
    AurenMusicTalentCapability(
      id: 'music_profile',
      name: 'Music Talent Profile',
      description: 'Build a focused profile for singers, instrumentalists, songwriters, composers, producers and DJs.',
    ),
    AurenMusicTalentCapability(
      id: 'voice_performance',
      name: 'Vocal Performance Review',
      description: 'Review an uploaded vocal recording for observable performance notes without claiming medical or studio-grade measurements.',
    ),
    AurenMusicTalentCapability(
      id: 'instrument_performance',
      name: 'Instrument Performance Review',
      description: 'Review an uploaded instrument performance and identify observable strengths and improvement areas.',
    ),
    AurenMusicTalentCapability(
      id: 'songwriting',
      name: 'Songwriting Lab',
      description: 'Help develop songwriting ideas, themes, structure and creative direction.',
    ),
    AurenMusicTalentCapability(
      id: 'music_portfolio',
      name: 'Music Portfolio',
      description: 'Organize tracks, performances, credits, achievements and evidence into a shareable portfolio.',
    ),
    AurenMusicTalentCapability(
      id: 'artist_brand',
      name: 'Artist Brand',
      description: 'Develop an artist identity, bio, positioning, visual direction and audience-facing story.',
    ),
    AurenMusicTalentCapability(
      id: 'release_plan',
      name: 'Release Plan',
      description: 'Create a practical plan for preparing and presenting a song or project release.',
    ),
    AurenMusicTalentCapability(
      id: 'setlist_builder',
      name: 'Setlist Builder',
      description: 'Build a performance setlist based on style, audience, event length and available songs.',
    ),
    AurenMusicTalentCapability(
      id: 'collab_match',
      name: 'Music Collaboration Match',
      description: 'Identify complementary music talents for bands, tracks, live performances or creative projects.',
    ),
    AurenMusicTalentCapability(
      id: 'music_opportunity',
      name: 'Music Opportunity Match',
      description: 'Compare a music talent profile with auditions, showcases, collaborations or other relevant opportunities.',
    ),
    AurenMusicTalentCapability(
      id: 'music_growth',
      name: 'Music Growth Roadmap',
      description: 'Create a development roadmap for musical skills, portfolio, performance evidence and audience growth.',
    ),
    AurenMusicTalentCapability(
      id: 'music_dossier',
      name: 'AI Music Talent Dossier',
      description: 'Create a structured overview of musical identity, skills, evidence, achievements, goals and next actions.',
    ),
  ];

  static bool contains(String id) =>
      all.any((item) => item.id == id.trim().toLowerCase());
}
