import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/post.dart';
import 'post_repository.dart';
class AurenCommunityMemoryFeedService {
 final FirebaseAuth auth; final PostRepository posts;
 AurenCommunityMemoryFeedService({FirebaseAuth? auth,PostRepository? posts}):auth=auth??FirebaseAuth.instance,posts=posts??PostRepository();
 String get uid=>auth.currentUser?.uid??(throw StateError('Sign in required'));
 Stream<List<AurenPost>> watch(String id)=>posts.watchCommunityFeed(id).map((xs)=>xs.where((p)=>p.contextLabel.startsWith('Community Memory:')).toList());
 Future<String> create({required String communityId,required String kind,required String title,required String body}) async {final c=communityId.trim(),k=kind.trim(),t=title.trim(),b=body.trim();if(c.isEmpty||!const {'milestone','decision','outcome'}.contains(k)||t.isEmpty||t.length>120||b.isEmpty||b.length>2000)throw ArgumentError('Invalid community memory entry.');final id='memory_'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+uid;await posts.createCommunityPost(AurenPost(id:id,authorId:uid,text:t+'\n\n'+b,contentType:'project',contextLabel:'Community Memory: '+k+' • '+t,communityId:c,createdAt:DateTime.now()));return id;}
}
