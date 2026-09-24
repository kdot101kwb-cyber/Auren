import '../../../core/models/product.dart';
import '../marketplace/marketplace_repository.dart';
class SupplierMatch { final AurenProduct product; final int score; final List<String> reasons; const SupplierMatch({required this.product,required this.score,required this.reasons}); }
class SupplierFinderService {
 final MarketplaceRepository _repo; SupplierFinderService({MarketplaceRepository? repo}):_repo=repo??MarketplaceRepository();
 Future<List<SupplierMatch>> find({required String query,String category='All',String currency=''}) async {
  final items=await _repo.watchPublic(query:query,category:category,currency:currency).first; final q=query.trim().toLowerCase();
  final words=q.split(RegExp(r'\s+')).where((x)=>x.length>1).toSet();
  final matches=items.map((p){ final hay='${p.name} ${p.description} ${p.category}'.toLowerCase(); final hits=words.where(hay.contains).length; var score=hits*25+20; if(score>100)score=100; final reasons=<String>[]; if(hits>0)reasons.add('يطابق طلبك'); if(p.businessId.isNotEmpty)reasons.add('مرتبط بنشاط تجاري'); reasons.add(p.service?'خدمة':'منتج'); return SupplierMatch(product:p,score:score,reasons:reasons); }).where((m)=>m.score>0).toList()..sort((a,b)=>b.score.compareTo(a.score));
  return matches.take(30).toList();
 }
}