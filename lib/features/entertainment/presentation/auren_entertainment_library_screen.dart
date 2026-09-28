import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../../services/entertainment/auren_offline_media_service.dart';
import 'auren_entertainment_job_detail_screen.dart';

class AurenEntertainmentLibraryScreen extends StatelessWidget {
  const AurenEntertainmentLibraryScreen({super.key});
  String _status(String value) {
    const labels = {'planning':'التخطيط','generating':'التوليد','processing':'المعالجة','ready':'جاهز','failed':'فشل','cancelled':'ملغاة'};
    return labels[value] ?? value;
  }
  IconData _icon(String mode) {
    switch (mode) {
      case 'أغنية': return Icons.music_note_rounded;
      case 'فيلم': return Icons.local_movies_rounded;
      case 'مسلسل': return Icons.tv_rounded;
      case 'فيديو': return Icons.video_library_rounded;
      case 'بودكاست': return Icons.podcasts_rounded;
      default: return Icons.auto_awesome_rounded;
    }
  }
  String? _jobMediaUrl(Map<String,dynamic> job) {
    dynamic value=job['musicArtifact'] ?? job['providerResult'];
    if(value is Map) value=value['url'] ?? value['output'];
    if(value is Map) value=value['url'];
    if(value is String && value.startsWith(RegExp(r'https?://'))) return value;
    final artifacts=job['movieArtifacts'];
    if(artifacts is List) {
      for(final item in artifacts) {
        dynamic v=item;
        if(v is Map) v=v['url'] ?? v['output'];
        if(v is Map) v=v['url'];
        if(v is String && v.startsWith(RegExp(r'https?://'))) return v;
      }
    }
    return null;
  }

  Future<void> _downloadSeries(BuildContext context, String jobId, String title) async {
    try {
      final package=await EntertainmentRepository().getFinalEpisodePackage(jobId);
      final raw=package?['finalizedEpisodes'];
      if(raw is! Map || raw.isEmpty) throw Exception('package');
      final result=await AurenOfflineMediaService.instance.downloadSeriesPackage(
        finalizedEpisodes:Map<String,dynamic>.from(raw),
        jobId:jobId,
      );
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('تم تنزيل ${result.length} حلقة من «$title» للحفظ Offline.')),
      );
    } catch (_) {
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('الحزمة النهائية للمسلسل غير جاهزة أو لا تحتوي روابط وسائط حقيقية.')),
      );
    }
  }

  Future<void> _downloadJob(BuildContext context, Map<String,dynamic> job) async {
    final mode=job['mode']?.toString()??'media';
    final title=job['title']?.toString().trim().isNotEmpty==true?job['title'].toString():job['idea']?.toString()??'AUREN Media';
    if(mode=='فيلم' && job['movieArtifacts'] is List) {
      final artifacts=job['movieArtifacts'] as List;
      var count=0;
      for(var i=0;i<artifacts.length;i++) {
        dynamic value=artifacts[i];
        if(value is Map) value=value['url'] ?? value['output'];
        if(value is Map) value=value['url'];
        if(value is String && value.startsWith(RegExp(r'https?://'))) {
          await _download(context,value,'$title • المشهد '+(i+1).toString(),'video',job['id']?.toString()??'');
          count++;
        }
      }
      if(context.mounted && count>0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تمت معالجة تنزيل $count مشهداً للحفظ Offline.')));
      }
      return;
    }
    final url=_jobMediaUrl(job);
    if(url==null)return;
    await _download(context,url,title,mode=='أغنية'?'audio':'video',job['id']?.toString()??'');
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول لعرض مكتبتك.')));
    final repo = EntertainmentRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('مكتبة AUREN Entertainment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16,12,16,32),
        children: [
          const Text('Offline', style: TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          FutureBuilder<List<AurenOfflineMedia>>(
            future: AurenOfflineMediaService.instance.list(),
            builder:(context,snapshot){
              final items=snapshot.data??const <AurenOfflineMedia>[];
              if(items.isEmpty)return const Card(child:ListTile(leading:Icon(Icons.download_for_offline_rounded),title:Text('لا توجد ملفات Offline بعد'),subtitle:Text('التنزيل يحفظ نسخة حقيقية داخل مساحة AUREN الخاصة بالتطبيق.')));
              return Card(child:Column(children:items.map((item)=>ListTile(
                leading:Icon(item.type=='audio'?Icons.music_note_rounded:Icons.movie_rounded),
                title:Text(item.title,maxLines:1,overflow:TextOverflow.ellipsis),
                subtitle:Text(item.type+' • '+(item.bytes/(1024*1024)).toStringAsFixed(1)+' MB'),
                trailing:IconButton(icon:const Icon(Icons.delete_outline_rounded),onPressed:() async{await AurenOfflineMediaService.instance.delete(item.id);if(context.mounted)(context as Element).markNeedsBuild();}),
              )).toList()));
            },
          ),
          const SizedBox(height:18),
          const Text('إنتاجاتك', style: TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          StreamBuilder<List<Map<String,dynamic>>>(
            stream: repo.watchEntertainmentCreationJobs(uid),
            builder: (context,snapshot) {
              final jobs=snapshot.data ?? const <Map<String,dynamic>>[];
              if(jobs.isEmpty) return const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('لا توجد مشاريع إنتاج بعد. ابدأ من Create Studio.')));
              return Column(children: jobs.map((job) {
                final id=job['id']?.toString() ?? '';
                final mode=job['mode']?.toString() ?? 'مشروع';
                final status=job['status']?.toString() ?? 'planning';
                final progress=((job['progress'] as num?)?.toInt() ?? 0).clamp(0,100);
                final title=job['title']?.toString().trim().isNotEmpty==true ? job['title'].toString() : job['idea']?.toString() ?? mode;
                return Card(
                  margin: const EdgeInsets.only(bottom:10),
                  child: ListTile(
                    leading: CircleAvatar(child:Icon(_icon(mode))),
                    title: Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
                    subtitle: Text(mode+' • '+_status(status)+' • '+progress.toString()+'%'),
                    trailing: status=='ready'
                      ? Row(mainAxisSize:MainAxisSize.min,children:[
                          if(_jobMediaUrl(job)!=null || mode=='مسلسل') IconButton(
                            tooltip:'تنزيل Offline',
                            icon:const Icon(Icons.download_for_offline_rounded),
                            onPressed:mode=='مسلسل'
                              ? ()=>_downloadSeries(context,id,title)
                              : ()=>_downloadJob(context,job),
                          ),
                          const Icon(Icons.play_circle_fill_rounded),
                        ])
                      : SizedBox(width:38,height:38,child:CircularProgressIndicator(value:progress/100)),
                    onTap: id.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute(builder:(_)=>AurenEntertainmentJobDetailScreen(jobId:id))),
                  ),
                );
              }).toList());
            },
          ),
          const SizedBox(height:18),
          const Text('متابعة المشاهدة', style: TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          StreamBuilder<List<Map<String,dynamic>>>(
            stream: repo.watchSeriesWatchProgress(uid),
            builder:(context,snapshot){
              final items=snapshot.data ?? const <Map<String,dynamic>>[];
              if(items.isEmpty) return const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('لا توجد مشاهدة محفوظة حالياً.')));
              return Card(child:Column(children:items.map((item){
                final title=item['title']?.toString().trim().isNotEmpty==true ? item['title'].toString() : 'مسلسل AUREN';
                final ep=item['episodeNumber']?.toString() ?? '?';
                final progress=((item['progress'] as num?)?.toDouble() ?? 0).clamp(0.0,1.0);
                final position=(item['positionSeconds'] as num?)?.toInt() ?? 0;
                return ListTile(
                  leading:const CircleAvatar(child:Icon(Icons.play_arrow_rounded)),
                  title:Text(title,maxLines:1,overflow:TextOverflow.ellipsis),
                  subtitle:Text('الحلقة '+ep+' • متابعة من '+_formatSeconds(position)),
                  trailing:SizedBox(width:42,height:42,child:CircularProgressIndicator(value:progress)),
                );
              }).toList()));
            },
          ),
          const SizedBox(height:18),
          const Card(child:ListTile(
            leading:Icon(Icons.info_outline_rounded),
            title:Text('الحفظ والتنزيل',style:TextStyle(fontWeight:FontWeight.w800)),
            subtitle:Text('المكتبة تحفظ حالة الإنتاج والمشاهدة. تنزيل ملفات الوسائط محلياً يحتاج مسار تخزين وصلاحيات Android مناسبة؛ لا نُنشئ نسخة محلية وهمية.'),
          )),
        ],
      ),
    );
  }
  String _formatSeconds(int seconds) {
    final hours=seconds~/3600;
    final minutes=((seconds%3600)~/60).toString().padLeft(2,'0');
    final secs=(seconds%60).toString().padLeft(2,'0');
    return hours>0 ? hours.toString()+':'+minutes+':'+secs : minutes+':'+secs;
  }
}
