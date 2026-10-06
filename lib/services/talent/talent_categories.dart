/// Canonical talent categories for AUREN Talent.
///
/// Talent focuses on personal ability, creativity, achievement and growth.
/// Employment, business operations, agriculture sectors and skilled-service
/// work belong to their dedicated AUREN systems, not Talent.
class AurenTalentCategory {
  final String id;
  final String name;
  final String description;

  const AurenTalentCategory({
    required this.id,
    required this.name,
    required this.description,
  });
}

class AurenTalentCategories {
  static const all = <AurenTalentCategory>[
    AurenTalentCategory(
      id: 'sports',
      name: 'Sports',
      description: 'Athletes, coaches, analysts, officials and sports performance.',
    ),
    AurenTalentCategory(
      id: 'music',
      name: 'Music',
      description: 'Singing, instruments, composition, production and DJ skills.',
    ),
    AurenTalentCategory(
      id: 'arts_design',
      name: 'Arts & Design',
      description: 'Visual art, illustration, graphic design, UI/UX and creative design.',
    ),
    AurenTalentCategory(
      id: 'film_acting',
      name: 'Film & Acting',
      description: 'Acting, directing, screenwriting, editing and production.',
    ),
    AurenTalentCategory(
      id: 'photography',
      name: 'Photography',
      description: 'Photography, visual storytelling and photo production.',
    ),
    AurenTalentCategory(
      id: 'technology',
      name: 'Technology & Coding',
      description: 'Coding, software building, engineering and technical creativity.',
    ),
    AurenTalentCategory(
      id: 'ai_innovation',
      name: 'AI & Innovation',
      description: 'AI projects, invention, experimentation and emerging technology.',
    ),
    AurenTalentCategory(
      id: 'writing',
      name: 'Writing & Literature',
      description: 'Writing, poetry, novels, journalism and storytelling.',
    ),
    AurenTalentCategory(
      id: 'creator',
      name: 'Creator & Media',
      description: 'Video creators, streamers, presenters, podcasters and digital media.',
    ),
    AurenTalentCategory(
      id: 'science_academic',
      name: 'Science & Academic',
      description: 'Scientific ability, mathematics, research and academic achievement.',
    ),
    AurenTalentCategory(
      id: 'gaming_esports',
      name: 'Gaming & Esports',
      description: 'Competitive gaming, game skills, strategy and esports.',
    ),
    AurenTalentCategory(
      id: 'fashion_beauty',
      name: 'Fashion & Beauty',
      description: 'Fashion, modeling, styling, makeup and beauty creativity.',
    ),
    AurenTalentCategory(
      id: 'food',
      name: 'Food & Cooking',
      description: 'Cooking, baking, culinary arts and food creativity.',
    ),
    AurenTalentCategory(
      id: 'languages',
      name: 'Languages & Communication',
      description: 'Languages, translation, public speaking and communication.',
    ),
    AurenTalentCategory(
      id: 'leadership_impact',
      name: 'Leadership & Social Impact',
      description: 'Community leadership, volunteering, advocacy and social impact.',
    ),
    AurenTalentCategory(
      id: 'other',
      name: 'Other',
      description: 'Emerging or specialized talent not yet covered by another category.',
    ),
  ];

  static const ids = <String>[
    'sports',
    'music',
    'arts_design',
    'film_acting',
    'photography',
    'technology',
    'ai_innovation',
    'writing',
    'creator',
    'science_academic',
    'gaming_esports',
    'fashion_beauty',
    'food',
    'languages',
    'leadership_impact',
    'other',
  ];

  static bool contains(String id) => ids.contains(id.trim().toLowerCase());

  static AurenTalentCategory byId(String id) {
    final normalized = id.trim().toLowerCase();
    return all.firstWhere(
      (category) => category.id == normalized,
      orElse: () => all.last,
    );
  }
}
