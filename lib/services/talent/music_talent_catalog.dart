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

    AurenMusicTalentCapability(
      id: 'vocal_skill_map',
      name: 'Vocal Skill Map',
      description: 'Map observable vocal skills, practice areas and development priorities from the talent profile and supplied evidence.',
    ),
    AurenMusicTalentCapability(
      id: 'instrument_skill_map',
      name: 'Instrument Skill Map',
      description: 'Map instrument-specific skills, repertoire, techniques and development priorities.',
    ),
    AurenMusicTalentCapability(
      id: 'pitch_practice',
      name: 'Pitch Practice Lab',
      description: 'Guide pitch practice and tuning exercises; any measured pitch requires an actual audio analysis capability or supplied recording.',
    ),
    AurenMusicTalentCapability(
      id: 'rhythm_practice',
      name: 'Rhythm Practice Lab',
      description: 'Build rhythm and timing practice plans from the musician profile and supplied performance evidence.',
    ),
    AurenMusicTalentCapability(
      id: 'producer_profile',
      name: 'Producer Profile',
      description: 'Create a focused talent profile for music producers, beatmakers and studio creators.',
    ),
    AurenMusicTalentCapability(
      id: 'discography',
      name: 'Discography',
      description: 'Organize releases, tracks, roles, credits and links as part of the music talent portfolio.',
    ),
    AurenMusicTalentCapability(
      id: 'performance_archive',
      name: 'Performance Archive',
      description: 'Organize live performances, recordings, videos and evidence chronologically.',
    ),
    AurenMusicTalentCapability(
      id: 'artist_showcase',
      name: 'Artist Showcase',
      description: 'Turn selected music evidence into a concise public showcase for the talent profile.',
    ),
    AurenMusicTalentCapability(
      id: 'music_achievements',
      name: 'Music Achievements',
      description: 'Structure verified or user-supplied musical achievements without inventing awards or results.',
    ),
    AurenMusicTalentCapability(
      id: 'band_profile',
      name: 'Band & Group Profile',
      description: 'Create a talent profile for a band or music group while keeping members and roles clear.',
    ),
    AurenMusicTalentCapability(
      id: 'music_scout',
      name: 'Music Talent Scout',
      description: 'Help identify promising music talent from profiles and supplied evidence using transparent criteria.',
    ),
    AurenMusicTalentCapability(
      id: 'music_evidence',
      name: 'Music Evidence Vault',
      description: 'Organize recordings, videos, releases, credits and achievements as evidence for a music talent profile.',
    ),
  ];

  static bool contains(String id) =>
      all.any((item) => item.id == id.trim().toLowerCase());
}
