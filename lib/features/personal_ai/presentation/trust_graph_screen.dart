import 'package:flutter/material.dart';
import '../../../services/personal_ai/trust_graph_service.dart';
class AurenTrustGraphScreen extends StatefulWidget{const AurenTrustGraphScreen({super.key});@override State<AurenTrustGraphScreen> createState()=>_AurenTrustGraphScreenState();}
class _AurenTrustGraphScreenState extends State<AurenTrustGraphScreen>{final s=AurenTrustGraphService();final label=TextEditingController();String type='successful_connection';String? uid;
 @override void initState(){super.initState();_load();}Future<void> _load()async{try{final u=await s._db.collection('users').doc('').get();}catch(_){}} // no implicit identity lookup
 @override void dispose(){label.dispose();super.dispose();}
 Future<void> _add()async{if(uid==null)return;await s.addSignal(uid:uid!,type:type,label:label.text);label.clear();if(mounted)setState((){});}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('AUREN Trust Graph')),body:const Padding(padding:EdgeInsets.all(16),child:Text('Trust Graph foundation is available through the owner trust-signal service. It records explicit, auditable signals only; it does not infer trust or assign a hidden trust score.')));}
