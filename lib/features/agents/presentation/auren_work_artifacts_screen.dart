import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/auren_work_artifact.dart';

class AurenWorkArtifactsScreen extends StatelessWidget {
  const AurenWorkArtifactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null) return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));

    final stream=FirebaseFirestore.instance
      .collection('users').doc(uid).collection('agent_artifacts')
      .orderBy('createdAt',descending:true).limit(100).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Work Center')),
      body: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
        stream: stream,
        builder:(context,snapshot){
          if(snapshot.hasError) return Center(child:Text('تعذر تحميل الأعمال: ${snapshot.error}'));
          if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
          final items=snapshot.data!.docs.map(AurenWorkArtifact.fromSnapshot).toList();
          if(items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('لا توجد أعمال داخلية بعد. أنشئ مهمة من Real Work Agents ثم وافق على الإجراء المقترح.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder:(_,__)=>const SizedBox(height:8),
            itemBuilder:(context,index){
              final x=items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child:Icon(Icons.description_outlined)),
                  title: Text(x.title),
                  subtitle: Text('${x.domain} • ${x.type} • ${x.status}\n${x.body}',maxLines:4,overflow:TextOverflow.ellipsis),
                  isThreeLine:true,
                  onTap:()=>showModalBottomSheet<void>(
                    context:context,
                    isScrollControlled:true,
                    builder:(sheet)=>SafeArea(
                      child:SingleChildScrollView(
                        padding:const EdgeInsets.all(20),
                        child:Column(
                          crossAxisAlignment:CrossAxisAlignment.start,
                          children:[
                            Text(x.title,style:Theme.of(sheet).textTheme.titleLarge),
                            const SizedBox(height:8),
                            Text('المجال: ${x.domain}'),
                            Text('النوع: ${x.type}'),
                            Text('الحالة: ${x.status}'),
                            if(x.agentId!=null) Text('الوكيل: ${x.agentId}'),
                            if(x.executionId!=null) Text('Execution: ${x.executionId}'),
                            const SizedBox(height:12),
                            Text(x.body),
                            if(x.payload.isNotEmpty)...[
                              const SizedBox(height:12),
                              Text('بيانات العمل',style:Theme.of(sheet).textTheme.titleMedium),
                              const SizedBox(height:6),
                              SelectableText(x.payload.toString()),
                            ],
                            const SizedBox(height:12),
                            const Text('هذا عنصر داخلي في AUREN. لا يعني أنه تم إرسال رسالة أو نشر محتوى أو إجراء دفع.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
