/// Cross-domain AI capabilities for AUREN Talent.
///
/// These capabilities apply to non-sports talent while sports keeps its
/// existing specialized tools. Work, jobs, business operations and agriculture
/// sector workflows remain in their dedicated AUREN systems.
class AurenTalentAiCapability {
  final String id;
  final String name;
  final String description;

  const AurenTalentAiCapability({
    required this.id,
    required this.name,
    required this.description,
  });
}

class AurenTalentAiCatalog {
  static const all = <AurenTalentAiCapability>[
    AurenTalentAiCapability(
      id: 'talent_passport',
      name: 'Talent Passport',
      description: 'Create a shareable profile of skills, achievements, goals and work samples.',
    ),
    AurenTalentAiCapability(
      id: 'skill_graph',
      name: 'Skill Graph',
      description: 'Map strengths, related skills, gaps and the next skills to develop.',
    ),
    AurenTalentAiCapability(
      id: 'portfolio_builder',
      name: 'Portfolio Builder',
      description: 'Turn projects, achievements and evidence into a structured talent portfolio.',
    ),
    AurenTalentAiCapability(
      id: 'showcase_story',
      name: 'Showcase Story',
      description: 'Build a concise story for presenting creative or technical talent to an audience.',
    ),
    AurenTalentAiCapability(
      id: 'talent_brand',
      name: 'Talent Brand',
      description: 'Define a clear personal identity, strengths, positioning and content direction.',
    ),
    AurenTalentAiCapability(
      id: 'growth_plan',
      name: 'Growth Plan',
      description: 'Create a practical development roadmap based on goals, level, time and evidence.',
    ),
    AurenTalentAiCapability(
      id: 'gap_radar',
      name: 'Gap Radar',
      description: 'Identify missing skills, evidence or profile elements that block the next level.',
    ),
    AurenTalentAiCapability(
      id: 'evidence_plan',
      name: 'Evidence Plan',
      description: 'Suggest credible evidence such as projects, certificates, results, links or samples.',
    ),
    AurenTalentAiCapability(
      id: 'opportunity_match',
      name: 'Opportunity Match',
      description: 'Compare a talent profile with a relevant opportunity and explain fit and gaps.',
    ),
    AurenTalentAiCapability(
      id: 'collaboration_match',
      name: 'Collaboration Match',
      description: 'Identify complementary talents for creative, technical or media collaborations.',
    ),
    AurenTalentAiCapability(
      id: 'talent_snapshot',
      name: 'Talent Snapshot',
      description: 'Summarize current identity, skills, achievements, goals and next action.',
    ),
    AurenTalentAiCapability(
      id: 'talent_dossier',
      name: 'AI Talent Dossier',
      description: 'Generate a structured analytical overview from the talent profile and its evidence.',
    ),
  ];

  static bool contains(String id) =>
      all.any((item) => item.id == id.trim().toLowerCase());

  static AurenTalentAiCapability? byId(String id) {
    final normalized = id.trim().toLowerCase();
    for (final item in all) {
      if (item.id == normalized) return item;
    }
    return null;
  }
}
