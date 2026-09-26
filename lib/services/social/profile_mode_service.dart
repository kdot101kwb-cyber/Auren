import 'package:cloud_firestore/cloud_firestore.dart';

enum AurenProfileMode { personal, creator, professional, business }

extension AurenProfileModeX on AurenProfileMode {
  String get id => name;

  String get label {
    switch (this) {
      case AurenProfileMode.personal: return 'Personal';
      case AurenProfileMode.creator: return 'Creator';
      case AurenProfileMode.professional: return 'Professional';
      case AurenProfileMode.business: return 'Business';
    }
  }

  String get description {
    switch (this) {
      case AurenProfileMode.personal:
        return 'للأصدقاء والتواصل والاهتمامات والرحلات.';
      case AurenProfileMode.creator:
        return 'للمحتوى والجمهور والمشاريع الإبداعية.';
      case AurenProfileMode.professional:
        return 'للمهارات والخبرة والفرص والتعاون المهني.';
      case AurenProfileMode.business:
        return 'للمنتجات والخدمات والعملاء والنمو.';
    }
  }

  static AurenProfileMode fromId(String? value) =>
      AurenProfileMode.values.firstWhere(
        (m) => m.id == value,
        orElse: () => AurenProfileMode.personal,
      );
}

class AurenProfileModeData {
  final AurenProfileMode mode;
  final String headline;
  final String bio;
  final List<String> skills;
  final List<String> interests;
  final List<String> links;
  final List<String> goals;
  final List<String> languages;
  final List<String> services;
  final List<String> achievements;
  final bool discoverable;
  final bool showContact;
  final DateTime? updatedAt;

  const AurenProfileModeData({
    required this.mode,
    required this.headline,
    required this.bio,
    required this.skills,
    required this.interests,
    required this.links,
    required this.goals,
    required this.languages,
    required this.services,
    required this.achievements,
    required this.discoverable,
    required this.showContact,
    this.updatedAt,
  });

  factory AurenProfileModeData.empty(AurenProfileMode mode) =>
      AurenProfileModeData(
        mode: mode,
        headline: '',
        bio: '',
        skills: const [],
        interests: const [],
        links: const [],
        goals: const [],
        languages: const [],
        services: const [],
        achievements: const [],
        discoverable: true,
        showContact: false,
      );

  factory AurenProfileModeData.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};

    List<String> list(String key, int max) => d[key] is List
        ? (d[key] as List).whereType<String>().map((v) => v.trim()).where((v) => v.isNotEmpty).take(max).toList()
        : <String>[];

    final ts = d['updatedAt'];

    return AurenProfileModeData(
      mode: AurenProfileModeX.fromId(d['mode'] as String?),
      headline: (d['headline'] as String? ?? '').trim(),
      bio: (d['bio'] as String? ?? '').trim(),
      skills: list('skills', 20),
      interests: list('interests', 20),
      links: list('links', 5),
      goals: list('goals', 10),
      languages: list('languages', 10),
      services: list('services', 15),
      achievements: list('achievements', 10),
      discoverable: d['discoverable'] != false,
      showContact: d['showContact'] == true,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'mode': mode.id,
        'headline': headline,
        'bio': bio,
        'skills': skills,
        'interests': interests,
        'links': links,
        'goals': goals,
        'languages': languages,
        'services': services,
        'achievements': achievements,
        'discoverable': discoverable,
        'showContact': showContact,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class AurenProfileModeService {
  final FirebaseFirestore _db;

  AurenProfileModeService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  String _uid(String uid) {
    final value = uid.trim();
    if (value.isEmpty || value.length > 128) {
      throw ArgumentError('Invalid uid.');
    }
    return value;
  }

  CollectionReference<Map<String, dynamic>> _modes(String uid) =>
      _db.collection('users').doc(_uid(uid)).collection('profile_modes');

  DocumentReference<Map<String, dynamic>> _settings(String uid) =>
      _db.collection('users').doc(_uid(uid)).collection('profile_settings').doc('current');

  Stream<AurenProfileMode> watchActiveMode(String uid) =>
      _settings(uid).snapshots().map((doc) =>
          AurenProfileModeX.fromId(doc.data()?['activeMode'] as String?));

  Future<AurenProfileMode> getActiveMode(String uid) async {
    final doc = await _settings(uid).get();
    return AurenProfileModeX.fromId(doc.data()?['activeMode'] as String?);
  }

  Future<void> setActiveMode(String uid, AurenProfileMode mode) {
    _uid(uid);
    return _settings(uid).set({
        'activeMode': mode.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
  }

  Stream<AurenProfileModeData> watch(String uid, AurenProfileMode mode) =>
      _modes(uid).doc(mode.id).snapshots().map((doc) => doc.exists
          ? AurenProfileModeData.fromDoc(doc)
          : AurenProfileModeData.empty(mode));

  Future<AurenProfileModeData> get(
    String uid,
    AurenProfileMode mode,
  ) async {
    final doc = await _modes(uid).doc(mode.id).get();
    return doc.exists
        ? AurenProfileModeData.fromDoc(doc)
        : AurenProfileModeData.empty(mode);
  }

  Future<void> save({
    required String uid,
    required AurenProfileMode mode,
    required String headline,
    required String bio,
    required List<String> skills,
    required List<String> interests,
    required List<String> links,
    required List<String> goals,
    required List<String> languages,
    required List<String> services,
    required List<String> achievements,
    required bool discoverable,
    required bool showContact,
  }) async {
    _uid(uid);

    String clean(String value, int max) {
      final trimmed = value.trim();
      return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
    }

    List<String> cleanList(
      List<String> values,
      int maxItems,
      int maxLength,
    ) =>
        values
            .map((v) => clean(v, maxLength))
            .where((v) => v.isNotEmpty)
            .take(maxItems)
            .toList();

    final h = clean(headline, 120);
    final b = clean(bio, 800);
    final cleanedSkills = cleanList(skills, 20, 60);
    final cleanedInterests = cleanList(interests, 20, 60);
    final cleanedLinks = cleanList(links, 5, 300);
    final cleanedGoals = cleanList(goals, 10, 120);
    final cleanedLanguages = cleanList(languages, 10, 40);
    final cleanedServices = cleanList(services, 15, 80);
    final cleanedAchievements = cleanList(achievements, 10, 160);

    if (h.isEmpty &&
        b.isEmpty &&
        cleanedSkills.isEmpty &&
        cleanedInterests.isEmpty &&
        cleanedGoals.isEmpty &&
        cleanedServices.isEmpty &&
        cleanedAchievements.isEmpty) {
      throw ArgumentError('أضف معلومة واحدة على الأقل للملف.');
    }

    await _modes(uid).doc(mode.id).set({
      'mode': mode.id,
      'headline': h,
      'bio': b,
      'skills': cleanedSkills,
      'interests': cleanedInterests,
      'links': cleanedLinks,
      'goals': cleanedGoals,
      'languages': cleanedLanguages,
      'services': cleanedServices,
      'achievements': cleanedAchievements,
      'discoverable': discoverable,
      'showContact': showContact,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
