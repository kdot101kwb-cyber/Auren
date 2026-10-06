class SportsTrustInfo {
  final String sourceName;
  final String coverage;
  final String updatePolicy;
  final bool isOfficial;
  final String trustLevel;

  const SportsTrustInfo({
    required this.sourceName,
    required this.coverage,
    required this.updatePolicy,
    required this.isOfficial,
    required this.trustLevel,
  });

  String get label => isOfficial ? 'Official source' : 'Data source';
}

class SportsTruthSignal {
  final String label;
  final String explanation;
  const SportsTruthSignal({required this.label, required this.explanation});
}

class TalentSportsTrustService {
  SportsTrustInfo forEntity({required String type}) {
    switch (type) {
      case 'players':
        return const SportsTrustInfo(
          sourceName: 'TheSportsDB',
          coverage: 'Player profile and available sports data',
          updatePolicy: 'Refresh from source when opened',
          isOfficial: false,
          trustLevel: 'Community data source',
        );
      case 'teams':
        return const SportsTrustInfo(
          sourceName: 'TheSportsDB',
          coverage: 'Team profile, events and available roster data',
          updatePolicy: 'Refresh from source when opened',
          isOfficial: false,
          trustLevel: 'Community data source',
        );
      case 'leagues':
        return const SportsTrustInfo(
          sourceName: 'TheSportsDB',
          coverage: 'League profile and available team data',
          updatePolicy: 'Refresh from source when opened',
          isOfficial: false,
          trustLevel: 'Community data source',
        );
      default:
        return const SportsTrustInfo(
          sourceName: 'AUREN Sports Data',
          coverage: 'Source not classified',
          updatePolicy: 'Verify before treating as official',
          isOfficial: false,
          trustLevel: 'Unverified',
        );
    }
  }

  SportsTruthSignal truthSignal({required String source, required String? updatedAt}) {
    if (source == 'TheSportsDB') {
      return const SportsTruthSignal(label: 'Community data', explanation: 'هذه البيانات مناسبة للاكتشاف والمساعدة، لكنها ليست تصريحاً رسمياً.');
    }
    if (source.trim().isEmpty) {
      return const SportsTruthSignal(label: 'Unverified', explanation: 'لا يوجد مصدر مصنف لهذه المعلومة.');
    }
    return SportsTruthSignal(label: 'Source identified', explanation: updatedAt == null || updatedAt.trim().isEmpty ? 'المصدر معروف، لكن وقت التحديث غير متوفر.' : 'المصدر معروف ووقت التحديث متوفر.');
  }

  String guidanceFor(String source) {
    if (source == 'TheSportsDB') {
      return 'مصدر رياضي مساعد وليس جهة رسمية. لا تعرض بياناته كاعتماد رسمي.';
    }
    return 'تحقق من الجهة الرسمية قبل عرض المعلومة كبيان موثق.';
  }
}
