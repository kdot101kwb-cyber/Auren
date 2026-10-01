import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../services/entertainment/auren_offline_media_service.dart';

class AurenEntertainmentMoviePlayerScreen extends StatefulWidget {
  final String title;
  final List<dynamic> scenes;
  const AurenEntertainmentMoviePlayerScreen({super.key, required this.title, required this.scenes});
  @override
  State<AurenEntertainmentMoviePlayerScreen> createState() => _AurenEntertainmentMoviePlayerScreenState();
}

class _AurenEntertainmentMoviePlayerScreenState extends State<AurenEntertainmentMoviePlayerScreen> {
  VideoPlayerController? _controller;
  int _index = 0;
  Future<void>? _init;
  bool _completed = false;

  List<Map<String,dynamic>> get _playable => widget.scenes.map((raw) {
    final s = raw is Map ? Map<String,dynamic>.from(raw as Map) : <String,dynamic>{};
    final o = s['output'] ?? s['media'] ?? s['video'];
    final url = o is Map ? o['url']?.toString() ?? '' : o?.toString() ?? '';
    return {'scene': s, 'url': url};
  }).where((e)=>e['url']?.toString().isNotEmpty == true).toList();

  @override void initState() { super.initState(); _load(0); }

  Future<void> _load(int index) async {
    if (_playable.isEmpty) return;
    final safe = index.clamp(0, _playable.length - 1);
    final old = _controller;
    final url = _playable[safe]['url'].toString();
    final localPath = await AurenOfflineMediaService.instance.localPathForUrl(url);
    final next = localPath != null
        ? VideoPlayerController.file(File(localPath))
        : VideoPlayerController.networkUrl(Uri.parse(url));
    final future = next.initialize();
    if (mounted) setState(() { _index = safe; _init = future; _completed = false; _controller = next; });
    try {
      await future;
      next.addListener(_listener);
      await next.play();
      if (old != null && old != next) await old.dispose();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تشغيل مشهد الفيلم.')));
      await next.dispose();
    }
  }

  void _listener() {
    final c=_controller;
    if (!mounted || c==null || !c.value.isInitialized) return;
    if (c.value.position >= c.value.duration && c.value.duration > Duration.zero && !_completed) {
      _completed=true;
      if (_index < _playable.length-1) _load(_index+1);
    }
    setState(() {});
  }

  @override void dispose() { _controller?.removeListener(_listener); _controller?.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final c=_controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines:1, overflow:TextOverflow.ellipsis),
        actions:[IconButton(tooltip:'مشاركة',onPressed:()=>SharePlus.instance.share(ShareParams(text:'شاهد فيلم AUREN: '+widget.title)),icon:const Icon(Icons.share_rounded))]
      ),
      body: c==null ? const Center(child:CircularProgressIndicator()) :
        FutureBuilder<void>(future:_init,builder:(context,s){
          if(s.connectionState!=ConnectionState.done) return const Center(child:CircularProgressIndicator());
          if(s.hasError || !c.value.isInitialized) return const Center(child:Text('تعذر تشغيل المشهد.'));
          return Column(children:[
            AspectRatio(aspectRatio:c.value.aspectRatio==0?16/9:c.value.aspectRatio,child:VideoPlayer(c)),
            Padding(padding:const EdgeInsets.all(16),child:Column(children:[
              Text('المشهد '+(_index+1).toString()+' من '+_playable.length.toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
              VideoProgressIndicator(c,allowScrubbing:true,padding:const EdgeInsets.symmetric(vertical:12)),
              Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                IconButton(onPressed:_index>0?()=>_load(_index-1):null,icon:const Icon(Icons.skip_previous_rounded)),
                IconButton.filled(onPressed:() async { if(c.value.isPlaying) await c.pause(); else await c.play(); if(mounted)setState((){}); },icon:Icon(c.value.isPlaying?Icons.pause_rounded:Icons.play_arrow_rounded)),
                IconButton(onPressed:_index<_playable.length-1?()=>_load(_index+1):null,icon:const Icon(Icons.skip_next_rounded)),
              ]),
              const SizedBox(height:8),
              Text('يتم تشغيل مشاهد الـAssembly بالترتيب، بدون اختلاق أي ملف وسائط غير موجود.',style:Theme.of(context).textTheme.bodySmall,textAlign:TextAlign.center),
            ]))
          ]);
        })
    );
  }
}
