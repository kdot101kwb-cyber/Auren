import 'package:cloud_firestore/cloud_firestore.dart';

class AurenCourse {
  final String id,title,description,category,level;
  final List<String> skills,lessons;
  final int minutes;
  AurenCourse({required this.id,required this.title,required this.description,required this.category,required this.level,required this.skills,required this.lessons,required this.minutes});
  factory AurenCourse.fromMap(String id,Map<String,dynamic> d)=>AurenCourse(
    id:id,title:d['title']?.toString()??'',description:d['description']?.toString()??'',
    category:d['category']?.toString()??'',level:d['level']?.toString()??'beginner',
    skills:List<String>.from(d['skills']??const []),lessons:List<String>.from(d['lessons']??const []),
    minutes:(d['minutes'] as num?)?.toInt()??0);
}
class AurenEducationService {
  final FirebaseFirestore db;
  AurenEducationService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;

  Stream<List<AurenCourse>> watchCourses({String category='All'}) =>
    db.collection('education_courses').where('published',isEqualTo:true).limit(100).snapshots().map((s){
      final list=s.docs.map((d)=>AurenCourse.fromMap(d.id,d.data())).where((c)=>category=='All'||c.category==category).toList();
      list.sort((a,b)=>a.title.compareTo(b.title)); return list;
    });

  Stream<DocumentSnapshot<Map<String,dynamic>>> watchEnrollment(String uid,String courseId)=>
    db.collection('users').doc(uid).collection('education_enrollments').doc(courseId).snapshots();

  Future<void> enroll({required String uid,required AurenCourse course}) async {
    if(uid.isEmpty||course.id.isEmpty) throw ArgumentError('بيانات التعلم غير صالحة');
    await db.collection('users').doc(uid).collection('education_enrollments').doc(course.id).set({
      'courseId':course.id,'title':course.title,'progress':0,'completedLessons':<String>[],
      'status':'active','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
  }

  Future<void> completeLesson({required String uid,required AurenCourse course,required int lessonIndex}) async {
    if(lessonIndex<0||lessonIndex>=course.lessons.length) throw ArgumentError('الدرس غير صالح');
    final ref=db.collection('users').doc(uid).collection('education_enrollments').doc(course.id);
    final snap=await ref.get(); if(!snap.exists) throw StateError('يجب التسجيل في الدورة أولاً');
    final done=List<String>.from(snap.data()?['completedLessons']??const []);
    final key=course.lessons[lessonIndex]; if(!done.contains(key)) done.add(key);
    final progress=course.lessons.isEmpty?100:((done.length/course.lessons.length)*100).round();
    await ref.update({'completedLessons':done,'progress':progress,'status':progress>=100?'completed':'active','updatedAt':FieldValue.serverTimestamp()});
  }

  Stream<List<Map<String,dynamic>>> watchMyLearning(String uid)=>
    db.collection('users').doc(uid).collection('education_enrollments').orderBy('updatedAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
}
