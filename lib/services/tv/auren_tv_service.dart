import 'dart:convert';
import 'package:http/http.dart' as http;\nimport 'package:shared_preferences/shared_preferences.dart';
class AurenTvChannel { final String id,name,logo,country,language,category,url,tvgId; const AurenTvChannel({required this.id,required this.name,required this.logo,required this.country,required this.language,required this.category,required this.url,this.tvgId='' }); }
class AurenTvService {
 AurenTvService._(); static final instance=AurenTvService._(); static const playlist='https://iptv-org.github.io/iptv/index.country.m3u';
 static const sourceName='iptv-org public playlist'; List<AurenTvChannel>? _cache; String? _epgUrl;
 Future<List<AurenTvChannel>> load({String country='',String category=''}) async { _cache ??= await _fetch(); final c=country.trim().toLowerCase(), k=category.trim().toLowerCase(); return _cache!.where((x)=>(c.isEmpty||x.country.toLowerCase()==c)&&(k.isEmpty||x.category.toLowerCase()==k)).take(300).toList(); }
 Future<List<AurenTvChannel>> _fetch() async { final r=await http.get(Uri.parse(playlist)).timeout(const Duration(seconds:20)); if(r.statusCode!=200) throw Exception('IPTV playlist unavailable'); final lines=const LineSplitter().convert(r.body); final out=<AurenTvChannel>[]; Map<String,String> meta={}; for(final line in lines){ if(line.startsWith('#EXTM3U')){_epgUrl=_attr(line,'x-tvg-url')??_attr(line,'url-tvg');} else if(line.startsWith('#EXTINF:')){meta={'name':_attr(line,'tvg-name')??line.split(',').last.trim(),'logo':_attr(line,'tvg-logo')??'','country':_attr(line,'tvg-country')??'','language':_attr(line,'tvg-language')??'','category':_attr(line,'group-title')??'','tvgId':_attr(line,'tvg-id')??''};} else if(line.startsWith('http')&&meta.isNotEmpty){out.add(AurenTvChannel(id:'tv-'+out.length.toString(),name:meta['name']!,logo:meta['logo']!,country:meta['country']!,language:meta['language']!,category:meta['category']!,url:line.trim(),tvgId:meta['tvgId']!));meta={};}} return out; }
 Future<Set<String>> favorites() async => (await SharedPreferences.getInstance()).getStringList('auren_tv_favorites')?.toSet()??{};\n Future<void> setFavorite(String id,bool value) async {final p=await SharedPreferences.getInstance();final s=p.getStringList('auren_tv_favorites')?.toSet()??<String>{};value?s.add(id):s.remove(id);await p.setStringList('auren_tv_favorites',s.toList());}\n Future<Map<String,String>?> nowNext(String tvgId) async {
  if(tvgId.isEmpty||_epgUrl==null||_epgUrl!.isEmpty)return null;
  try {
   final r=await http.get(Uri.parse(_epgUrl!)).timeout(const Duration(seconds:15));
   if(r.statusCode!=200)return null;
   final re=RegExp(r'<programme\\b([^>]*)>([\\s\\S]*?)</programme>',caseSensitive:false);
   final now=DateTime.now().toUtc(); Map<String,String>? current,next;
   for(final m in re.allMatches(r.body).take(10000)){
    final a=m.group(1)!,b=m.group(2)!;
    final id=RegExp(r'channel="([^"]*)"').firstMatch(a)?.group(1)??'';
    if(id!=tvgId)continue;
    final start=RegExp(r'start="([^"]*)"').firstMatch(a)?.group(1)??'';
    final stop=RegExp(r'stop="([^"]*)"').firstMatch(a)?.group(1)??'';
    DateTime dt(String v){try{return DateTime.parse('${v.substring(0,4)}-${v.substring(4,6)}-${v.substring(6,8)}T${v.substring(8,10)}:${v.substring(10,12)}:${v.substring(12,14)}Z');}catch(_){return DateTime.fromMillisecondsSinceEpoch(0,isUtc:true);}}
    final title=RegExp(r'<title[^>]*>([\\s\\S]*?)</title>',caseSensitive:false).firstMatch(b)?.group(1)?.replaceAll('&amp;','&')??'';
    if(dt(start).isBefore(now)&&dt(stop).isAfter(now))current={'title':title,'start':start,'stop':stop};
    else if(dt(start).isAfter(now)&&(next==null||dt(start).isBefore(dt(next['start']!))))next={'title':title,'start':start,'stop':stop};
   }
   return {'current':current?['title']??'','next':next?['title']??'','nextStart':next?['start']??''};
  }catch(_){return null;}
 }
 static String? _attr(String s,String key){final m=RegExp(key+'="([^"]*)"').firstMatch(s);return m?.group(1);}
}