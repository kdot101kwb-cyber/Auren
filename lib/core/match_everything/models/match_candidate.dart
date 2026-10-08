enum MatchCandidateType {
  supplier,
  product,
  business,
  service,
  opportunity,
}

class MatchCandidate {
  final String id;
  final MatchCandidateType type;
  final String title;
  final String? countryCode;
  final double score;
  final Map<String, dynamic> metadata;

  const MatchCandidate({
    required this.id,
    required this.type,
    required this.title,
    this.countryCode,
    this.score = 0,
    this.metadata = const {},
  });
}
