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
    AurenMusicTalentCapability(
      id: 'song_generator',
      name: 'AI Song Generator',
      description: 'Create a production-ready generation brief from lyrics, genre, mood, instruments, BPM and key.',
    ),
    AurenMusicTalentCapability(
      id: 'cover_art',
      name: 'Cover Art Studio',
      description: 'Create a cover-art brief from the song identity, title, lyrics and optional reference image.',
    ),
    AurenMusicTalentCapability(
      id: 'music_video',
      name: 'Music Video Studio',
      description: 'Plan a complete music video from the song, cover image or reference images, including scenes, motion and timing.',
    ),
    AurenMusicTalentCapability(
      id: 'image_to_video',
      name: 'Image-to-Video Music',
      description: 'Turn an artist or cover image into a music-video scene concept with camera motion, lighting and visual rhythm.',
    ),
    AurenMusicTalentCapability(
      id: 'lyric_video',
      name: 'Lyric Video Studio',
      description: 'Build a synchronized lyric-video plan from the song structure and lyrics.',
    ),
    AurenMusicTalentCapability(
      id: 'audio_visualizer',
      name: 'Audio Visualizer',
      description: 'Design an audio-reactive visualizer concept matched to the track's rhythm and energy.',
    ),
    AurenMusicTalentCapability(
      id: 'artist_promo_video',
      name: 'Artist Promo Video',
      description: 'Create a short promotional video concept from artist imagery and the song identity.',
    ),
    AurenMusicTalentCapability(
      id: 'social_music_clips',
      name: 'Music Social Clips',
      description: 'Generate multiple short-form clip concepts with hooks, cut points and captions for the song.',
    ),
    AurenMusicTalentCapability(
      id: 'music_storyboard',
      name: 'Music Video Storyboard',
      description: 'Turn the song concept into a shot-by-shot storyboard before video production.',
    ),
    AurenMusicTalentCapability(
      id: 'release_media_pack',
      name: 'Release Media Pack',
      description: 'Prepare a coordinated release pack: cover, lyric video, visualizer, promo clips and metadata.',
    ),
    AurenMusicTalentCapability(
      id: 'production_stems',
      name: 'Production & Stems Plan',
      description: 'Plan vocal, instrumental, drums and other stems and explain what source files are needed.',
    ),
    AurenMusicTalentCapability(
      id: 'music_creator_suite',
      name: 'Music Creator Suite',
      description: 'Coordinate the song workflow from idea and recording through analysis, artwork, video and release media.',
    ),
  ];

  static bool contains(String id) =>
      all.any((item) => item.id == id.trim().toLowerCase());
}
