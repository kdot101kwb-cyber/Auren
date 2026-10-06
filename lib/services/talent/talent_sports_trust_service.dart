class SportsTrustInfo {
  final String sourceName;
  final String coverage;
  final String updatePolicy;
  final bool isOfficial;

  const SportsTrustInfo({
    required this.sourceName,
    required this.coverage,
    required this.updatePolicy,
    required this.isOfficial,
  });

  String get label => isOfficial ? 'Verified source' : 'Data source';
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
        );
      case 'teams':
        return const SportsTrustInfo(
          sourceName: 'TheSportsDB',
          coverage: 'Team profile, events and available roster data',
          updatePolicy: 'Refresh from source when opened',
          isOfficial: false,
        );
      case 'leagues':
        return const SportsTrustInfo(
          sourceName: 'TheSportsDB',
          coverage: 'League profile and available team data',
          updatePolicy: 'Refresh from source when opened',
          isOfficial: false,
        );
      default:
        return const SportsTrustInfo(
          sourceName: 'AUREN Sports Data',
          coverage: 'Source not classified',
          updatePolicy: 'Verify before treating as official',
          isOfficial: false,
        );
    }
  }
}
