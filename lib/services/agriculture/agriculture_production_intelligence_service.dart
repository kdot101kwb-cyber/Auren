import 'package:cloud_functions/cloud_functions.dart';

class AgricultureProductionPoint {
  final String iso3,country,item,unit; final int year; final double? production,yieldValue,area;
  const AgricultureProductionPoint({required this.iso3,required this.country,required this.item,required this.year,this.production,this.yieldValue,this.area,this.unit='' });
  factory AgricultureProductionPoint.fromMap(Map<dynamic,dynamic> m){double? n(dynamic v)=>v==null?null:double.tryParse(v.toString());return AgricultureProductionPoint(iso3:'${m['iso3']??''}',country:'${m['country']??''}',item:'${m['item']??''}',year:int.tryParse('${m['year']??0}')??0,production:n(m['production']),yieldValue:n(m['yieldValue']),area:n(m['area']),unit:'${m['unit']??''}');}
}
class AgricultureForecastPoint {
 final int year; final double predictedProduction; final String method;
 const AgricultureForecastPoint({required this.year,required this.predictedProduction,required this.method});
 factory AgricultureForecastPoint.fromMap(Map<dynamic,dynamic> m)=>AgricultureForecastPoint(year:int.tryParse('${m['year']??0}')??0,predictedProduction:double.tryParse('${m['predictedProduction']??m['predicted']??0}')??0,method:'${m['method']??''}');
}
class AgricultureMetricForecast {
 final int year; final double? value;
 const AgricultureMetricForecast({required this.year,this.value});
 factory AgricultureMetricForecast.fromMap(Map<dynamic,dynamic> m)=>AgricultureMetricForecast(year:int.tryParse('${m['year']??0}')??0,value:double.tryParse('${m['predicted']??m['value']??0}') );
}
class AgricultureRevenueProfitForecast {
 final int year; final double? production,yieldValue,area,revenue,profit;
 final String? currency,unit;
 const AgricultureRevenueProfitForecast({required this.year,this.production,this.yieldValue,this.area,this.revenue,this.profit,this.currency,this.unit});
 factory AgricultureRevenueProfitForecast.fromMap(Map<dynamic,dynamic> m)=>AgricultureRevenueProfitForecast(year:int.tryParse('${m['year']??0}')??0,production:_n(m['predictedProduction']),yieldValue:_n(m['predictedYield']),area:_n(m['predictedArea']),revenue:_n(m['revenue']),profit:_n(m['profit']),currency:m['revenueCurrency']?.toString(),unit:m['revenueUnit']?.toString() );
 static double? _n(dynamic v)=>v==null?null:double.tryParse(v.toString());
}
class AgricultureProductionIntelligenceService {
 final FirebaseFunctions _functions;
 AgricultureProductionIntelligenceService({FirebaseFunctions? functions}):_functions=functions??FirebaseFunctions.instance;

 Future<List<AgricultureProductionPoint>> history({String? iso3,String? item,int? fromYear,int? toYear}) async {
  final r=await _functions.httpsCallable('aurenAgriProductionHistory').call({'iso3':iso3,'item':item,'fromYear':fromYear,'toYear':toYear});
  final d=Map<String,dynamic>.from(r.data as Map),rows=(d['rows'] is List ? List<dynamic>.from(d['rows'] as List) : const <dynamic>[]);
  return rows.map((e)=>AgricultureProductionPoint.fromMap(Map<dynamic,dynamic>.from(e as Map))).toList();
 }
 Future<Map<String,dynamic>> forecastBundle({String? iso3,String? item,int horizon=5}) async {
  final r=await _functions.httpsCallable('aurenAgriProductionForecast').call({'iso3':iso3,'item':item,'horizon':horizon});
  return Map<String,dynamic>.from(r.data as Map);
 }
 Future<List<AgricultureForecastPoint>> forecast({String? iso3,String? item,int horizon=5}) async {
  final d=await forecastBundle(iso3:iso3,item:item,horizon:horizon),rows=(d['forecast'] is List ? List<dynamic>.from(d['forecast'] as List) : const <dynamic>[]);
  return rows.map((e)=>AgricultureForecastPoint.fromMap(Map<dynamic,dynamic>.from(e as Map))).toList();
 }
 Future<List<AgricultureMetricForecast>> yieldForecast({String? iso3,String? item,int horizon=5}) async {
  final d=await forecastBundle(iso3:iso3,item:item,horizon:horizon),rows=(d['yieldForecast'] is List ? List<dynamic>.from(d['yieldForecast'] as List) : const <dynamic>[]);
  return rows.map((e)=>AgricultureMetricForecast.fromMap(Map<dynamic,dynamic>.from(e as Map))).toList();
 }
 Future<List<AgricultureMetricForecast>> areaForecast({String? iso3,String? item,int horizon=5}) async {
  final d=await forecastBundle(iso3:iso3,item:item,horizon:horizon),rows=(d['areaForecast'] is List ? List<dynamic>.from(d['areaForecast'] as List) : const <dynamic>[]);
  return rows.map((e)=>AgricultureMetricForecast.fromMap(Map<dynamic,dynamic>.from(e as Map))).toList();
 }
 Future<List<AgricultureRevenueProfitForecast>> revenueProfitForecast({String? iso3,String? item,int horizon=5}) async {
  final d=await forecastBundle(iso3:iso3,item:item,horizon:horizon),rows=(d['revenueForecast'] is List ? List<dynamic>.from(d['revenueForecast'] as List) : const <dynamic>[]);
  return rows.map((e)=>AgricultureRevenueProfitForecast.fromMap(Map<dynamic,dynamic>.from(e as Map))).toList();
 }
 Future<Map<String,dynamic>> seasonComparison({String? iso3,String? item}) async {
  final r=await _functions.httpsCallable('aurenAgriSeasonComparison').call({'iso3':iso3,'item':item});
  return Map<String,dynamic>.from(r.data as Map);
 }
 Future<Map<String,dynamic>> cropScenario({required double baseProduction,double yieldChangePct=0,double areaChangePct=0,double priceChangePct=0,double costChangePct=0,String? iso3,String? item}) async {
  final r=await _functions.httpsCallable('aurenAgriCropScenario').call({'iso3':iso3,'item':item,'baseProduction':baseProduction,'yieldChangePct':yieldChangePct,'areaChangePct':areaChangePct,'priceChangePct':priceChangePct,'costChangePct':costChangePct});
  return Map<String,dynamic>.from(r.data as Map);
 }
 Future<Map<String,dynamic>> linkedIntelligence({required String iso3,required String crop}) async {
  final r=await _functions.httpsCallable('aurenAgriProductionIntelligence').call({'iso3':iso3,'crop':crop});
  return Map<String,dynamic>.from(r.data as Map);
 }

  Future<Map<String, dynamic>> forecastBacktest({String? iso3, String? item}) async {
    final r = await _functions.httpsCallable('aurenAgriForecastBacktest').call({'iso3': iso3, 'item': item});
    return Map<String, dynamic>.from(r.data as Map);
  }
}