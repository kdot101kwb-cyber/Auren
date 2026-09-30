class AurenPodcastCatalogItem {
  final String name;
  final String host;
  final String category;
  final String language;
  final String description;
  final String sourceStatus;

  const AurenPodcastCatalogItem({
    required this.name,
    required this.host,
    required this.category,
    required this.language,
    required this.description,
    this.sourceStatus = 'metadata_only',
  });
}

/// Curated podcast discovery metadata.
/// This file intentionally contains no audio/stream URLs. Playback should use
/// an authorized RSS/feed/provider integration when one is connected.
const aurenPodcastCatalog = <AurenPodcastCatalogItem>[
  AurenPodcastCatalogItem(
    name: 'The Diary Of A CEO',
    host: 'Steven Bartlett',
    category: 'Life & Business',
    language: 'English',
    description: 'Long-form conversations about life, leadership, business and personal growth.',
  ),
  AurenPodcastCatalogItem(
    name: 'How I Built This',
    host: 'Guy Raz',
    category: 'Founders & Business',
    language: 'English',
    description: 'Founder stories covering how companies and brands were built.',
  ),
  AurenPodcastCatalogItem(
    name: 'The Tim Ferriss Show',
    host: 'Tim Ferriss',
    category: 'Life & Performance',
    language: 'English',
    description: 'Long-form conversations on learning, performance, habits and the lives of high achievers.',
  ),
  AurenPodcastCatalogItem(
    name: 'My First Million',
    host: 'Sam Parr & Shaan Puri',
    category: 'Business Ideas',
    language: 'English',
    description: 'Business ideas, opportunities, markets and practical entrepreneurship conversations.',
  ),
  AurenPodcastCatalogItem(
    name: 'Acquired',
    host: 'Ben Gilbert & David Rosenthal',
    category: 'Business Strategy',
    language: 'English',
    description: 'Deep dives into how major companies and industries were built.',
  ),
  AurenPodcastCatalogItem(
    name: 'Founders',
    host: 'David Senra',
    category: 'Entrepreneurs',
    language: 'English',
    description: 'Lessons from biographies and stories of notable entrepreneurs.',
  ),
  AurenPodcastCatalogItem(
    name: 'The Knowledge Project',
    host: 'Shane Parrish',
    category: 'Thinking & Decisions',
    language: 'English',
    description: 'Mental models, decision-making, leadership and clear thinking.',
  ),
  AurenPodcastCatalogItem(
    name: 'The GaryVee Audio Experience',
    host: 'Gary Vaynerchuk',
    category: 'Creators & Business',
    language: 'English',
    description: 'Entrepreneurship, marketing, social media, creators and personal growth.',
  ),
  AurenPodcastCatalogItem(
    name: 'The School of Greatness',
    host: 'Lewis Howes',
    category: 'Life & Growth',
    language: 'English',
    description: 'Personal development, relationships, leadership, health and success stories.',
  ),
  AurenPodcastCatalogItem(
    name: 'Habits and Hustle',
    host: 'Jen Cohen',
    category: 'Life & Business',
    language: 'English',
    description: 'Conversations about habits, business, performance and personal development.',
  ),
  AurenPodcastCatalogItem(
    name: 'Young and Profiting (YAP)',
    host: 'Hala Taha',
    category: 'Entrepreneurship & Self-Improvement',
    language: 'English',
    description: 'Entrepreneurship, sales, marketing, careers and self-improvement.',
  ),
  AurenPodcastCatalogItem(
    name: 'Aspire with Emma Grede',
    host: 'Emma Grede',
    category: 'Leadership & Entrepreneurship',
    language: 'English',
    description: 'Conversations around entrepreneurship, leadership, ambition and building businesses.',
  ),
  AurenPodcastCatalogItem(
    name: 'Founder's Story',
    host: 'Daniel Robbins',
    category: 'Founders & Creators',
    language: 'English',
    description: 'Founder and creator conversations about business, identity, reinvention and growth.',
  ),
];
