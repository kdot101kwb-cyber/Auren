class AurenProfile {
  final String uid, displayName, bio;
  final String? photoUrl;
  final List<String> interests;
  const AurenProfile({required this.uid,required this.displayName,this.bio='',this.photoUrl,this.interests=const []});
  Map<String,dynamic> toMap()=>{'displayName':displayName,'bio':bio,'photoUrl':photoUrl,'interests':interests};
  factory AurenProfile.fromMap(String uid,Map<String,dynamic> m)=>AurenProfile(uid:uid,displayName:m['displayName']??'AUREN User',bio:m['bio']??'',photoUrl:m['photoUrl'] as String?,interests:List<String>.from(m['interests'] as List? ?? const []));
}