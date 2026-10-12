/// Advisory trust-signal aggregation for AUREN profiles and listings.
///
/// This is not identity verification, fraud detection, or an authorization
/// decision. Missing evidence is neutral; consumers must show the explanation
/// and must not treat this score alone as proof of safety.
enum TrustSignalKind {
  verifiedContact,
  completedTransaction,
  helpfulReview,
  disputedReview,
  policyViolation,
}

class TrustSignal {
  const TrustSignal({
    required this.id,
    required this.kind,
    required this.occurredAt,
    this.weight = 1,
    this.evidenceReference,
  });

  final String id;
  final TrustSignalKind kind;
  final DateTime occurredAt;
  final double weight;
  final String? evidenceReference;
}

class TrustAssessment {
  const TrustAssessment({
    required this.score,
    required this.label,
    required this.explanations,
    required this.evidenceCount,
  });

  /// Advisory score from 0 to 100. It is not a probability.
  final int score;
  final String label;
  final List<String> explanations;
  final int evidenceCount;
}

class TrustSignalAssessor {
  const TrustSignalAssessor();

  TrustAssessment assess({
    required Iterable<TrustSignal> signals,
    required DateTime now,
  }) {
    final unique = <String, TrustSignal>{};
    for (final signal in signals) {
      if (signal.id.trim().isEmpty ||
          signal.occurredAt.isAfter(now) ||
          !signal.weight.isFinite ||
          signal.weight <= 0) {
        continue;
      }
      unique.putIfAbsent(signal.id, () => signal);
    }

    var points = 50.0;
    final explanations = <String>[];
    final counted = <TrustSignal>[];
    for (final signal in unique.values) {
      final age = now.difference(signal.occurredAt);
      final recency = age <= const Duration(days: 90) ? 1.0 :
          age <= const Duration(days: 365) ? 0.6 : 0.3;
      final evidenceFactor =
          (signal.evidenceReference?.trim().isNotEmpty ?? false) ? 1.0 : 0.65;
      final delta = _delta(signal.kind) * signal.weight.clamp(0.25, 2.0).toDouble() *
          recency * evidenceFactor;
      points += delta;
      counted.add(signal);
      if (delta > 0) {
        explanations.add(_explanation(signal.kind));
      } else if (delta < 0) {
        explanations.add(_explanation(signal.kind));
      }
    }

    final score = points.round().clamp(0, 100).toInt();
    final label = counted.isEmpty ? 'Not enough evidence' :
        score >= 75 ? 'Positive signals' :
        score >= 45 ? 'Mixed or limited signals' : 'Caution: negative signals';
    if (counted.isEmpty) {
      explanations.add('No eligible signals; score is neutral, not verified.');
    }
    return TrustAssessment(
      score: score,
      label: label,
      explanations: List.unmodifiable(explanations.toSet()),
      evidenceCount: counted.length,
    );
  }

  double _delta(TrustSignalKind kind) {
    switch (kind) {
      case TrustSignalKind.verifiedContact: return 8;
      case TrustSignalKind.completedTransaction: return 6;
      case TrustSignalKind.helpfulReview: return 3;
      case TrustSignalKind.disputedReview: return -5;
      case TrustSignalKind.policyViolation: return -18;
    }
  }

  String _explanation(TrustSignalKind kind) {
    switch (kind) {
      case TrustSignalKind.verifiedContact: return 'Contact verification signal recorded';
      case TrustSignalKind.completedTransaction: return 'Completed transaction signal recorded';
      case TrustSignalKind.helpfulReview: return 'Helpful review signal recorded';
      case TrustSignalKind.disputedReview: return 'Disputed review signal recorded';
      case TrustSignalKind.policyViolation: return 'Policy violation signal recorded';
    }
  }
}
