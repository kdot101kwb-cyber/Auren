/// Offline-first helpers for Business & Economy MVP.
///
/// Matching is advisory only. It never contacts a buyer or seller.
class AurenBusinessMatchInput {
  const AurenBusinessMatchInput({
    required this.buyerNeed,
    required this.sellerOffer,
    this.buyerLocation = '',
    this.sellerLocation = '',
    this.buyerCategory = '',
    this.sellerCategory = '',
  });

  final String buyerNeed;
  final String sellerOffer;
  final String buyerLocation;
  final String sellerLocation;
  final String buyerCategory;
  final String sellerCategory;
}

class AurenBusinessMatchResult {
  const AurenBusinessMatchResult({
    required this.score,
    required this.reasons,
  });

  final int score;
  final List<String> reasons;
}

class AurenBusinessEconomyLogic {
  const AurenBusinessEconomyLogic._();

  static Set<String> _tokens(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.length > 1)
      .toSet();

  static AurenBusinessMatchResult scoreMatch(AurenBusinessMatchInput input) {
    final need = _tokens(input.buyerNeed);
    final offer = _tokens(input.sellerOffer);
    final shared = need.intersection(offer);
    final reasons = <String>[];
    var score = 0;

    if (need.isNotEmpty && offer.isNotEmpty) {
      score += ((shared.length / need.length) * 60).round().clamp(0, 60);
      if (shared.isNotEmpty) reasons.add('Shared need/offer terms: ${shared.take(5).join(', ')}');
    }

    final buyerCategory = input.buyerCategory.trim().toLowerCase();
    final sellerCategory = input.sellerCategory.trim().toLowerCase();
    if (buyerCategory.isNotEmpty && buyerCategory == sellerCategory) {
      score += 25;
      reasons.add('Category matches');
    }

    final buyerLocation = input.buyerLocation.trim().toLowerCase();
    final sellerLocation = input.sellerLocation.trim().toLowerCase();
    if (buyerLocation.isNotEmpty && sellerLocation.isNotEmpty &&
        buyerLocation == sellerLocation) {
      score += 15;
      reasons.add('Location matches');
    }

    return AurenBusinessMatchResult(
      score: score.clamp(0, 100),
      reasons: List.unmodifiable(reasons),
    );
  }

  static List<String> buildGrowthSteps({
    required String goal,
    required String customerGroup,
    required String nextAction,
  }) {
    final cleanGoal = goal.trim();
    final cleanCustomers = customerGroup.trim();
    final cleanAction = nextAction.trim();
    return List.unmodifiable([
      if (cleanGoal.isNotEmpty) 'Goal: $cleanGoal',
      if (cleanCustomers.isNotEmpty) 'Customer group: $cleanCustomers',
      if (cleanAction.isNotEmpty) 'Next action: $cleanAction',
    ]);
  }
}
