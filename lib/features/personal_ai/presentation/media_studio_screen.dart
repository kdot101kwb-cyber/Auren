import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/media/auren_media_service.dart';

class AurenMediaStudioScreen extends StatefulWidget {
  const AurenMediaStudioScreen({super.key});
  @override State<AurenMediaStudioScreen> createState()=>_AurenMediaStudioScreenState();
}
class _AurenMediaStudioScreenState extends State<AurenMediaStudioScreen>{
  final _picker=ImagePicker(); final _service=AurenMediaService();
  Uint8List? _bytes; String _name=''; String _type='application/octet-stream'; bool _uploading=false; String? _url; bool _video=false;

  Future<void> _pick(ImageSource source) async {
    final file=await _picker.pickMedia();
    if(file==null)return;
    final bytes=await file.readAsBytes();
    if(!mounted)return;
    setState(() {
      _bytes = bytes;
      _name = file.name;
      _type = file.mimeType ?? 'application/octet-stream';
      _video = (file.mimeType ?? '').startsWith('video/');
      _url = null;
    });
  }
  Future<void> _upload() async {
    final uid=FirebaseAurenAuthService().currentUserId;
    if(uid==null||_bytes==null)return;
    setState(()=>_uploading=true);
    try{
      final r=await _service.uploadBytes(uid:uid,bytes:_bytes!,fileName:_name,contentType:_type);
      if(!mounted)return; setState(()=>_url=r.downloadUrl);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم رفع الوسائط بنجاح')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل الرفع: $e')));}
    finally{if(mounted)setState(()=>_uploading=false);}
  }
  @override Widget build(BuildContext context){
    final uid=FirebaseAurenAuthService().currentUserId;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول لاستخدام الوسائط.')));
    return Scaffold(appBar:AppBar(title:const Text('Media Studio')),body:ListView(padding:const EdgeInsets.all(16),children:[
      const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('اختيار صورة أو فيديو من الجهاز ثم رفعه إلى مساحة AUREN الخاصة بك. الحد 25MB.'))),
      FilledButton.icon(onPressed:()=>_pick(ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined),label:const Text('اختيار من الجهاز')),
      const SizedBox(height:10),
      if(_bytes!=null)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
        if(!_video)Image.memory(_bytes!,height:220,fit:BoxFit.cover) else const Padding(padding:EdgeInsets.all(40),child:Icon(Icons.video_file_outlined,size:64)),
        const SizedBox(height:8),Text(_name),
      ]))),
      const SizedBox(height:10),
      FilledButton.icon(onPressed:_uploading||_bytes==null?null:_upload,icon:const Icon(Icons.cloud_upload_outlined),label:Text(_uploading?'جاري الرفع…':'رفع الوسائط')),
      if(_url!=null) ...[const SizedBox(height:14),const Text('Download URL:'),SelectableText(_url!)],
    ]));
  }
}