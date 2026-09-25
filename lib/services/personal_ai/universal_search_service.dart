import '../../core/models/business.dart';
import '../../core/models/post.dart';
import '../../core/models/product.dart';
import '../business/business_repository.dart';
import '../marketplace/marketplace_repository.dart';
import '../social/post_repository.dart';

enum AurenSearchType { business, product, post }
class AurenSearchResult { final String id,title,subtitle; final AurenSearchType type; const AurenSearchResult({required this.id,required this.title,required this.subtitle,required this.type}); }
class AurenUniversalSearchService {
 final BusinessRepository businesses; final MarketplaceRepository products; final PostRepository posts;
 AurenUniversalSearchService({BusinessRepository? businesses,MarketplaceRepository? products,PostRepository? posts}):businesses=businesses??BusinessRepository(),products=products??MarketplaceRepository(),posts=posts??PostRepository();
 Stream<List<AurenSearchResult>> watch(String query){final q=query.trim().toLowerCase();if(q.isEmpty)return Stream.value(const <AurenSearchResult>[]);return businesses.watchPublic(query:q).asyncMap((bs) async {final ps=await products.watchPublic(query:q).first;final fs=await posts.watchFeed().first;final out=<AurenSearchResult>[...bs.map((b)=>AurenSearchResult(id:b.id,title:b.name,subtitle:'Business • '+b.city+', '+b.country,type:AurenSearchType.business)),...ps.map((p)=>AurenSearchResult(id:p.id,title:p.name,subtitle:'Product • '+p.category,type:AurenSearchType.product)),...fs.where((p)=>('${p.text} '+p.contentType).toLowerCase().contains(q)).map((p)=>AurenSearchResult(id:p.id,title:p.text.isEmpty?'AUREN Post':p.text,subtitle:'Post • '+p.contentType,type:AurenSearchType.post))];return out.take(60).toList();});}
}
