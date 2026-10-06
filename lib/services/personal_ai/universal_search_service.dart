import 'package:firebase_core/firebase_core.dart';
import '../../core/models/business.dart';
import '../../core/models/post.dart';
import '../../core/models/product.dart';
import '../business/business_repository.dart';
import '../marketplace/marketplace_repository.dart';
import '../social/post_repository.dart';

enum AurenSearchType { business, product, post }
class AurenSearchResult { final String id,title,subtitle; final AurenSearchType type; const AurenSearchResult({required this.id,required this.title,required this.subtitle,required this.type}); }
class AurenUniversalSearchService {
 final BusinessRepository? _businesses; final MarketplaceRepository? _products; final PostRepository? _posts;
 AurenUniversalSearchService({BusinessRepository? businesses,MarketplaceRepository? products,PostRepository? posts}):_businesses=businesses,_products=products,_posts=posts;
 Stream<List<AurenSearchResult>> watch(String query) {
   final q = query.trim().toLowerCase();
   if (q.isEmpty) return Stream.value(const <AurenSearchResult>[]);
   final safeQuery = q.length > 80 ? q.substring(0, 80) : q;
   if (Firebase.apps.isEmpty) return Stream.value(const <AurenSearchResult>[]);
   final businesses = _businesses ?? BusinessRepository();
   final products = _products ?? MarketplaceRepository();
   final posts = _posts ?? PostRepository();
   return businesses.watchPublic(query: safeQuery).asyncMap((bs) async {
     final results = await Future.wait([
       products.watchPublic(query: safeQuery).first,
       posts.watchFeed().first,
     ]);
     final ps = results[0] as List<AurenProduct>;
     final fs = results[1] as List<AurenPost>;
     final out = <AurenSearchResult>[
       ...bs.take(20).map((b) => AurenSearchResult(
         id: b.id,
         title: b.name,
         subtitle: 'Business • ${b.city}, ${b.country}',
         type: AurenSearchType.business,
       )),
       ...ps.take(20).map((p) => AurenSearchResult(
         id: p.id,
         title: p.name,
         subtitle: 'Product • ${p.category}',
         type: AurenSearchType.product,
       )),
       ...fs.where((p) => ('${p.text} ${p.contentType}').toLowerCase().contains(safeQuery)).take(20).map((p) => AurenSearchResult(
         id: p.id,
         title: p.text.isEmpty ? 'AUREN Post' : p.text,
         subtitle: 'Post • ${p.contentType}',
         type: AurenSearchType.post,
       )),
     ];
     return out.take(60).toList();
   });
 }
}
