import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AurenOfflineMedia {
  final String id, title, type, path, sourceUrl;
  final int bytes;
  final DateTime savedAt;
  const AurenOfflineMedia({required this.id, required this.title, required this.type, required this.path, required this.sourceUrl, required this.bytes, required this.savedAt});
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'type':type,'path':path,'sourceUrl':sourceUrl,'bytes':bytes,'savedAt':savedAt.toIso8601String()};
  static AurenOfflineMedia? fromJson(Map<String,dynamic> j){
    final path=j['path']?.toString()??'', id=j['id']?.toString()??'', title=j['title']?.toString()??'', type=j['type']?.toString()??'media', source=j['sourceUrl']?.toString()??'';
    final date=DateTime.tryParse(j['savedAt']?.toString()??'');
    if(id.isEmpty||path.isEmpty||date==null)return null;
    return AurenOfflineMedia(id:id,title:title,type:type,path:path,sourceUrl:source,bytes:(j['bytes'] as num?)?.toInt()??0,savedAt:date);
  }
}
class AurenOfflineMediaService {
  static const _key='auren_offline_media_v1';
  static const _queueKey='auren_offline_download_queue_v1';
  final Set<String> _pauseRequested=<String>{};
  static final instance=AurenOfflineMediaService._();
  AurenOfflineMediaService._();
  Future<Directory> _directory() async {
    final root=await getApplicationDocumentsDirectory();
    final dir=Directory(root.path+'/auren_offline');
    if(!await dir.exists()) await dir.create(recursive:true);
    return dir;
  }
  String _safe(String v){final s=v.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'),'_'); return s.isEmpty?'media':s.substring(0,s.length.clamp(1,80).toInt());}
  Future<void> _saveQueue(List<Map<String,dynamic>> items) async {
    final p=await SharedPreferences.getInstance();
    await p.setStringList(_queueKey,items.map(jsonEncode).toList());
  }
  Future<List<Map<String,dynamic>>> queue() async {
    final p=await SharedPreferences.getInstance();
    return (p.getStringList(_queueKey)??const []).map((e){try{return Map<String,dynamic>.from(jsonDecode(e) as Map);}catch(_){return <String,dynamic>{};}}).where((e)=>e.isNotEmpty).toList();
  }
  Future<void> enqueue({required String url,required String title,required String type,String? id}) async {
    final q=await queue(); final source=url.trim();
    if(source.isEmpty || q.any((e)=>e['url']==source && e['status']!='ready')) return;
    q.add({'id':id?.trim().isNotEmpty==true?id:'QUEUE_' + DateTime.now().millisecondsSinceEpoch.toString() + '_' + source.hashCode.abs().toString(),'url':source,'title':title,'type':type,'status':'queued','progress':0,'received':0,'total':0,'updatedAt':DateTime.now().toIso8601String()});
    await _saveQueue(q);
  }
  Future<void> pauseQueued(String id) async { final q=await queue(); _pauseRequested.add(id); for(final e in q.where((e)=>e['id']==id)){e['status']='paused';e['updatedAt']=DateTime.now().toIso8601String();} await _saveQueue(q); }
  Future<void> resumeQueued(String id) async { final q=await queue(); _pauseRequested.remove(id); for(final e in q.where((e)=>e['id']==id)){e['status']='queued';e['updatedAt']=DateTime.now().toIso8601String();} await _saveQueue(q); await processQueue(); }
  Future<void> cancelQueued(String id) async {
    final q=await queue(); for(final e in q.where((e)=>e['id']==id)){e['status']='cancelled';e['updatedAt']=DateTime.now().toIso8601String();} await _saveQueue(q);
  }
  Future<void> processQueue({void Function(Map<String,dynamic>)? onChanged}) async {
    final q=await queue();
    for(final e in q){
      if(e['status']=='ready'||e['status']=='cancelled'||e['status']=='paused') continue;
      e['status']='downloading'; await _saveQueue(q); onChanged?.call(Map.from(e));
      try {
        await download(url:e['url'].toString(),title:e['title'].toString(),type:e['type']?.toString()??'media',id:e['id']?.toString(),onProgress:(received,total) async {
          if(_pauseRequested.contains(e['id']?.toString())) throw StateError('download_paused');
          e['received']=received;e['total']=total;e['progress']=total>0?(received/total*100).clamp(0,100):0;e['updatedAt']=DateTime.now().toIso8601String();await _saveQueue(q);onChanged?.call(Map.from(e));
        });
        e['status']='ready';e['progress']=100;e['updatedAt']=DateTime.now().toIso8601String();await _saveQueue(q);onChanged?.call(Map.from(e));
      } catch (_) {
        e['status']=_pauseRequested.contains(e['id']?.toString())?'paused':'failed';e['updatedAt']=DateTime.now().toIso8601String();await _saveQueue(q);onChanged?.call(Map.from(e));
      }
    }
  }
  Future<void> _save(List<AurenOfflineMedia> items) async {
    final p=await SharedPreferences.getInstance();
    await p.setStringList(_key,items.map((e)=>jsonEncode(e.toJson())).toList());
  }
  Future<List<AurenOfflineMedia>> list() async {
    final p=await SharedPreferences.getInstance(); final raw=p.getStringList(_key)??const [];
    final out=<AurenOfflineMedia>[];
    for(final s in raw){try{final m=AurenOfflineMedia.fromJson(Map<String,dynamic>.from(jsonDecode(s) as Map)); if(m!=null&&await File(m.path).exists())out.add(m);}catch(_){}} 
    if(out.length!=raw.length)await _save(out); out.sort((a,b)=>b.savedAt.compareTo(a.savedAt)); return out;
  }
  Future<String?> localPathForUrl(String url) async {for(final m in await list()){if(m.sourceUrl==url&&await File(m.path).exists())return m.path;}return null;}
  Future<List<AurenOfflineMedia>> downloadSeriesPackage({required Map<String,dynamic> finalizedEpisodes, required String jobId, void Function(int,int)? onProgress}) async {
    final out=<AurenOfflineMedia>[];
    final entries=finalizedEpisodes.entries.toList()..sort((a,b)=>a.key.compareTo(b.key));
    for(final entry in entries){
      dynamic value=entry.value;
      if(value is Map) value=value['video'] ?? value['videoUrl'] ?? value['url'] ?? value['media'];
      if(value is Map) value=value['url'];
      if(value is String && value.startsWith(RegExp(r'https?://'))){
        out.add(await download(url:value,title:'AUREN • الحلقة '+entry.key,type:'video',id:'${jobId}_ep_${entry.key}',onProgress:onProgress));
      }
    }
    return out;
  }

  Future<void> enqueueSeriesPackage({required Map<String,dynamic> finalizedEpisodes,required String jobId}) async {
    final entries=finalizedEpisodes.entries.toList()..sort((a,b)=>a.key.compareTo(b.key));
    for(final entry in entries){
      dynamic value=entry.value;
      if(value is Map) value=value['video'] ?? value['videoUrl'] ?? value['url'] ?? value['media'];
      if(value is Map) value=value['url'];
      if(value is String && value.startsWith(RegExp(r'https?://'))){
        await enqueue(url:value,title:'AUREN • الحلقة '+entry.key,type:'video',id:jobId+'_ep_'+entry.key);
      }
    }
  }

  Future<void> retryFailed(String id) async {
    final q=await queue();
    for(final e in q.where((e)=>e['id']==id && e['status']=='failed')) { e['status']='queued'; e['updatedAt']=DateTime.now().toIso8601String(); }
    await _saveQueue(q);
    await processQueue();
  }
  Future<int> offlineBytes() async {
    final items=await list();
    return items.fold<int>(0,(sum,item)=>sum+item.bytes);
  }

  Future<void> setLowData(bool enabled) async {
    final p=await SharedPreferences.getInstance();
    await p.setBool('auren_offline_low_data_v1',enabled);
  }
  Future<bool> lowDataEnabled() async {
    final p=await SharedPreferences.getInstance();
    return p.getBool('auren_offline_low_data_v1') ?? false;
  }

  Future<AurenOfflineMedia> download({required String url,required String title,required String type,String? id,void Function(int,int)? onProgress}) async {
    final source=url.trim(); final uri=Uri.tryParse(source);
    if(uri==null||(uri.scheme!='http'&&uri.scheme!='https'))throw ArgumentError('Only HTTP(S) media URLs can be downloaded.');
    final existing=await localPathForUrl(source); if(existing!=null)return (await list()).firstWhere((e)=>e.path==existing);
    final dir=await _directory(); final last=uri.pathSegments.isEmpty?'':uri.pathSegments.last;
    final ext=RegExp(r'\.([a-zA-Z0-9]{2,5})$').firstMatch(last)?.group(1)?.toLowerCase()??(type=='audio'?'mp3':'mp4');
    final mediaId=(id?.trim().isNotEmpty==true?id!.trim():'${DateTime.now().millisecondsSinceEpoch}_${source.hashCode.abs()}');
    final file=File(dir.path+'/'+_safe(mediaId)+'.'+_safe(ext)); final temp=File(file.path+'.part');
    final client=http.Client();
    try{
      final existingPart=await temp.length();
      final request=http.Request('GET',uri);
      if(existingPart>0) request.headers['Range']='bytes=$existingPart-';
      final response=await client.send(request);
      if(response.statusCode==416 && await temp.exists()){await temp.delete(); return download(url:url,title:title,type:type,id:id,onProgress:onProgress);}
      if(response.statusCode<200||response.statusCode>=300)throw HttpException('HTTP ${response.statusCode}');
      final total=(response.contentLength??0)+(response.statusCode==206?existingPart:0);
      var received=existingPart;
      if(response.statusCode==200 && existingPart>0){received=0;}
      final sink=temp.openWrite(mode: response.statusCode==206 ? FileMode.append : FileMode.write);
      if(response.statusCode<200||response.statusCode>=300)throw HttpException('HTTP ${response.statusCode}');
      await response.stream.forEach((chunk){sink.add(chunk);received+=chunk.length;onProgress?.call(received,total);});
      await sink.close(); await temp.rename(file.path);
      final media=AurenOfflineMedia(id:mediaId,title:title.trim().isEmpty?'AUREN Media':title.trim(),type:type,path:file.path,sourceUrl:source,bytes:received,savedAt:DateTime.now());
      final items=await list(); items.removeWhere((e)=>e.sourceUrl==source||e.id==mediaId); items.add(media); await _save(items); return media;
    }catch(_){rethrow;}finally{client.close();}
  }
  Future<void> delete(String id) async {final items=await list();for(final m in items.where((e)=>e.id==id)){final f=File(m.path);if(await f.exists())await f.delete();}items.removeWhere((e)=>e.id==id);await _save(items);}
}
