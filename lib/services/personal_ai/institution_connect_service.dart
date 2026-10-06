import '../business/business_repository.dart';
import '../goals/goal_repository.dart';

class AurenInstitutionMatch{final String businessId,name,category,city,country,reason;final int signals;const AurenInstitutionMatch({required this.businessId,required this.name,required this.category,required this.city,required this.country,required this.reason,required this.signals});}
class InstitutionConnectService{
 final BusinessRepository businesses;final GoalRepository goals;
 InstitutionConnectService({BusinessRepository? businesses,GoalRepository? goals}):businesses=businesses??BusinessRepository(),goals=goals??GoalRepository();
 Future<List<AurenInstitutionMatch>> find(String uid,{String query=''})async{
  final all=await businesses.watchPublic().first;final own=all.where((b)=>b.ownerId==uid).map((b)=>b.id).toSet();final gs=await goals.watch(uid).first;
  final terms=<String>{...query.toLowerCase().split(RegExp(r'\s+')).where((x)=>x.length>2),...gs.where((g)=>g.status=='active').expand((g)=>g.title.toLowerCase().split(RegExp(r'\s+'))).where((x)=>x.length>2)};
  final out=<AurenInstitutionMatch>[];
  for(final b in all){if(own.contains(b.id))continue;final hay=[b.name,b.description,b.category,b.city,b.country,b.businessType].join(' ').toLowerCase();final institutional=b.businessType.toLowerCase().contains('institution')||b.businessType.toLowerCase().contains('organization')||b.category.toLowerCase().contains('education')||b.category.toLowerCase().contains('government')||b.category.toLowerCase().contains('ngo');if(!institutional)continue;final hits=terms.where(hay.contains).length;final signals=hits+(b.verified?1:0);if(signals>0)out.add(AurenInstitutionMatch(businessId:b.id,name:b.name,category:b.category,city:b.city,country:b.country,reason:hits>0?'تطابق مع هدفك أو مجال اهتمامك':'جهة عامة موثقة قد تكون ذات صلة',signals:signals));}
  out.sort((a,b)=>b.signals.compareTo(a.signals));return out.take(30).toList();
 }
}