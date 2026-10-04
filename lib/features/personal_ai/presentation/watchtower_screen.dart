import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/watchtower_service.dart';
class AurenWatchtowerScreen extends StatefulWidget{const AurenWatchtowerScreen({super.key});@override State<AurenWatchtowerScreen> createState()=>_AurenWatchtowerScreenState();}
class _AurenWatchtowerScreenState extends State<AurenWatchtowerScreen>{final a=FirebaseAurenAuthService();late Future<List<AurenWatchtowerAlert>> f;@override void initState(){super.initState();f=_load();}Future<List<AurenWatchtowerAlert>> _load()async{final u=a.currentUserId;if(u==null)throw StateError('Sign in required');return WatchtowerService().scan(u);} @override
Widget build(BuildContext c) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('AUREN Watchtower'),
      actions: [
        IconButton(
          onPressed: () => setState(() => f = _load()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<AurenWatchtowerAlert>>(
      future: f,
      builder: (c, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'مراقبة ذكية',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...s.data!.map(
              (x) => Card(
                child: ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text(x.title),
                  subtitle: Text(x.detail),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
