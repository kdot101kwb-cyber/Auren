import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/intent_engine/models/intent_entity.dart';
import '../../core/match_everything/match_everything.dart';
import '../../core/match_everything/models/match_candidate.dart';
import '../../core/match_everything/models/match_request.dart';

/// Firestore-backed candidate lookup for AUREN's existing public business
/// directory. It deliberately does not invent supplier records: suppliers are
/// surfaced only when a real public business document matches the request.
class FirestoreMatchCandidateSource implements MatchCandidateSource {
  FirestoreMatchCandidateSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _countryAliases = <String, String>{
    'SD': 'sudan',
    'CN': 'china',
    'EG': 'egypt',
    'TR': 'turkey',
    'KE': 'kenya',
    'CA': 'canada',
    'US': 'united states',
    'GB': 'united kingdom',
  };

  @override
  Future<List<MatchCandidate>> find(MatchRequest request) async {
    if (request.userId.trim().isEmpty || request.query.trim().isEmpty) {
      return const [];
    }

    final snapshot = await _db
        .collection('businesses')
        .where('visibility', isEqualTo: 'public')
        .limit(100)
        .get();

    final query = request.query.toLowerCase();
    final tokens = _tokens(query);
    final requestedCountry = _requestedCountry(request);
    final candidates = <MatchCandidate>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['status'] as String? ?? 'active') != 'active') continue;

      final name = data['name'] as String? ?? '';
      final description = data['description'] as String? ?? '';
      final category = data['category'] as String? ?? '';
      final businessType = data['businessType'] as String? ?? '';
      final city = data['city'] as String? ?? '';
      final country = data['country'] as String? ?? '';
      final searchable = '$name $description $category $businessType $city $country'
          .toLowerCase();

      final hits = tokens.where(searchable.contains).length;
      final countryMatches = requestedCountry == null ||
          country.toLowerCase().contains(requestedCountry) ||
          _countryAliases[requestedCountry]?.let((alias) =>
                  country.toLowerCase().contains(alias)) ==
              true;
      if (hits == 0 || !countryMatches) continue;

      final verified = data['verified'] == true;
      final score = ((hits / (tokens.isEmpty ? 1 : tokens.length)) * .8 +
              (verified ? .2 : 0))
          .clamp(0.0, 1.0)
          .toDouble();

      candidates.add(MatchCandidate(
        id: doc.id,
        type: _isSupplierQuery(query, businessType, category)
            ? MatchCandidateType.supplier
            : MatchCandidateType.business,
        title: name.isEmpty ? 'Business' : name,
        countryCode: request.entities.where((e) => e.type == IntentEntityType.country).firstOrNull?.value,
        score: score,
        metadata: {
          'source': 'firestore.businesses',
          'description': description,
          'category': category,
          'businessType': businessType,
          'city': city,
          'country': country,
          'verified': verified,
          'website': data['website'] as String? ?? '',
        },
      ));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(20).toList(growable: false);
  }

  String? _requestedCountry(MatchRequest request) {
    final entity = request.entities.where(
      (e) => e.type == IntentEntityType.country,
    ).firstOrNull;
    final code = entity?.value;
    if (code == null || code.trim().isEmpty) return null;
    return _countryAliases[code.toUpperCase()] ?? code.toLowerCase();
  }

  bool _isSupplierQuery(String query, String type, String category) {
    const terms = [
      'supplier', 'wholesaler', 'factory', 'manufacturer',
      'مورد', 'مصنع', 'جملة', 'شركة توريد',
    ];
    return terms.any(query.contains) ||
        type.toLowerCase().contains('supplier') ||
        category.toLowerCase().contains('supplier');
  }

  Set<String> _tokens(String value) {
    const ignored = {
      'عايز', 'اريد', 'أريد', 'من', 'في', 'على', 'the', 'for', 'from',
      'find', 'search', 'want', 'need', 'supplier', 'wholesaler',
      'factory', 'manufacturer', 'مورد', 'مصنع', 'جملة', 'شركة', 'توريد',
      'الصين', 'china', 'السودان', 'sudan', 'مصر', 'egypt', 'تركيا', 'turkey',
      'كندا', 'canada', 'أمريكا', 'america', 'usa', 'بريطانيا', 'britain',
    };
    const synonyms = <String, List<String>>{
      'ملابس': ['clothing', 'clothes', 'apparel', 'garments', 'textile'],
      'قماش': ['fabric', 'textile', 'cloth'],
      'أقمشة': ['fabric', 'textile', 'cloth'],
      'هواتف': ['phone', 'phones', 'mobile', 'smartphone', 'electronics'],
      'موبايل': ['phone', 'mobile', 'smartphone'],
      'إلكترونيات': ['electronics', 'electronic'],
      'أثاث': ['furniture'],
      'أحذية': ['shoes', 'footwear'],
      'غذاء': ['food', 'grocery'],
      'مواد': ['materials', 'supplies'],
      'بلاستيك': ['plastic'],
      'دواجن': ['poultry', 'chicken'],
      'أسماك': ['fish', 'seafood'],
    };
    final result = <String>{};
    for (final token in value
        .toLowerCase()
        .split(RegExp(r'[^\\p{L}\\p{N}]+', unicode: true))) {
      if (token.length <= 2 || ignored.contains(token)) continue;
      result.add(token);
      result.addAll(synonyms[token] ?? const []);
    }
    return result;
  }
}

extension _NullableLet<T> on T? {
  R? let<R>(R Function(T value) transform) {
    final value = this;
    return value == null ? null : transform(value);
  }
}
