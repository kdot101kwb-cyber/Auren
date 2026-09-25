import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class AurenMediaUploadResult {
  final String mediaId;
  final String downloadUrl;
  final String path;
  final String contentType;
  final int sizeBytes;
  const AurenMediaUploadResult({required this.mediaId,required this.downloadUrl,required this.path,required this.contentType,required this.sizeBytes});
}

class AurenMediaService {
  final FirebaseStorage _storage;
  AurenMediaService({FirebaseStorage? storage}):_storage=storage??FirebaseStorage.instance;

  Future<AurenMediaUploadResult> uploadBytes({
    required String uid,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String folder='uploads',
  }) async {
    if(bytes.isEmpty) throw ArgumentError('Media is empty');
    if(bytes.length>25*1024*1024) throw ArgumentError('Media exceeds 25 MB MVP limit');
    final safe=fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
    final id=DateTime.now().microsecondsSinceEpoch.toString();
    final path='users/$uid/media/$folder/$id-$safe';
    final ref=_storage.ref(path);
    final task=await ref.putData(bytes,SettableMetadata(contentType:contentType,customMetadata:{'ownerId':uid,'mediaId':id}));
    final url=await task.ref.getDownloadURL();
    return AurenMediaUploadResult(mediaId:id,downloadUrl:url,path:path,contentType:contentType,sizeBytes:bytes.length);
  }

  Future<void> delete(String uid,String path) async {
    if(!path.startsWith('users/$uid/media/')) throw ArgumentError('Invalid media path');
    await _storage.ref(path).delete();
  }
}
