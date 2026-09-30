/// Curated examples for the AUREN TV directory.
/// These entries are metadata only; playback URLs must come from an authorized source.
class AurenTvCatalogChannel {
  final String name;
  final String category;
  final String region;
  final String language;
  final String description;
  final String sourceStatus;

  const AurenTvCatalogChannel({
    required this.name,
    required this.category,
    required this.region,
    required this.language,
    required this.description,
    this.sourceStatus = 'metadata_only',
  });
}

const aurenTvCatalogExamples = <AurenTvCatalogChannel>[
  AurenTvCatalogChannel(name:'MBC3', category:'Kids', region:'Middle East', language:'Arabic', description:'قناة أطفال عربية'),
  AurenTvCatalogChannel(name:'Baraem', category:'Kids', region:'Middle East', language:'Arabic', description:'محتوى أطفال عربي'),
  AurenTvCatalogChannel(name:'Majid Kids', category:'Kids', region:'Middle East', language:'Arabic', description:'محتوى أطفال عربي'),
  AurenTvCatalogChannel(name:'Spacetoon', category:'Cartoon', region:'Middle East', language:'Arabic', description:'رسوم متحركة وأنمي مدبلج'),
  AurenTvCatalogChannel(name:'Cartoon Network', category:'Cartoon', region:'Americas', language:'English', description:'رسوم متحركة'),
  AurenTvCatalogChannel(name:'Boomerang', category:'Cartoon', region:'Americas', language:'English', description:'رسوم متحركة كلاسيكية'),
  AurenTvCatalogChannel(name:'Nickelodeon', category:'Kids', region:'Americas', language:'English', description:'محتوى أطفال وعائلي'),
  AurenTvCatalogChannel(name:'Disney Channel', category:'Kids', region:'Americas', language:'English', description:'محتوى أطفال وعائلي'),
  AurenTvCatalogChannel(name:'Animax', category:'Anime', region:'Asia', language:'Japanese', description:'برامج أنمي'),
  AurenTvCatalogChannel(name:'RetroCrush', category:'Anime', region:'Americas', language:'English', description:'أنمي كلاسيكي'),
  AurenTvCatalogChannel(name:'CBeebies', category:'Kids', region:'Europe', language:'English', description:'محتوى تعليمي وترفيهي للأطفال'),
  AurenTvCatalogChannel(name:'Crunchyroll Channel', category:'Anime', region:'Americas', language:'English', description:'محتوى أنمي'),
  AurenTvCatalogChannel(name:'Disney Junior', category:'Kids', region:'Americas', language:'English', description:'محتوى للصغار'),
  AurenTvCatalogChannel(name:'Nick Jr.', category:'Kids', region:'Americas', language:'English', description:'محتوى للصغار'),
];
