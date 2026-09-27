import '../../../core/models/business.dart';

class AurenReviewInsights {
  final int total;
  final double average;
  final int positive;
  final int neutral;
  final int negative;
  final List<String> themes;
  const AurenReviewInsights({required this.total,required this.average,required this.positive,required this.neutral,required this.negative,required this.themes});
}

class AurenReviewIntelligenceService {
  AurenReviewInsights analyze(List<AurenBusinessReview> reviews){
    if(reviews.isEmpty)return const AurenReviewInsights(total:0,average:0,positive:0,neutral:0,negative:0,themes:[]);
    var positive=0,neutral=0,negative=0; final words=<String,int>{};
    const positiveWords=['ممتاز','رائع','جيد','جميل','سريع','محترم','موثوق','excellent','great','good','fast','amazing'];
    const negativeWords=['سيئ','سيء','بطيء','مشكلة','متأخر','احتيال','poor','bad','slow','problem','late'];
    const themeWords=['السعر','جودة','خدمة','خدمات','منتج','منتجات','توصيل','دعم','موظفين','موقع','price','quality','service','delivery','support'];
    for(final r in reviews){
      if(r.rating>=4)positive++; else if(r.rating<=2)negative++; else neutral++;
      final t=r.text.toLowerCase();
      for(final w in [...positiveWords,...negativeWords,...themeWords]){
        if(t.contains(w))words[w]=(words[w]??0)+1;
      }
    }
    final ranked=words.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    return AurenReviewInsights(total:reviews.length,average:reviews.map((r)=>r.rating).reduce((a,b)=>a+b)/reviews.length,positive:positive,neutral:neutral,negative:negative,themes:ranked.take(5).map((e)=>e.key).toList());
  }
}
