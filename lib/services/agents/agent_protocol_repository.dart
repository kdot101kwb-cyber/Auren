import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../core/models/agent_message.dart';

class AurenAgentProtocolRepository {
  final FirebaseAuth _auth;
  final String endpoint;
  AurenAgentProtocolRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance, endpoint = const String.fromEnvironment('AUREN_ACTION_EXECUTOR_URL');

  Future<void> enqueue(AurenAgentMessage message) async {
    if (endpoint.isEmpty) throw StateError('AUREN_ACTION_EXECUTOR_URL is not configured.');
    final user = _auth.currentUser;
    if (user == null) throw StateError('User is not authenticated.');
    final token = await user.getIdToken();
    final envelope = {'protocol':'AUREN-A2A','version':'1.0','messageId':message.messageId,'senderAgentId':message.senderAgentId,'recipientAgentId':message.recipientAgentId,'type':message.type,'payload':message.payload};
    final response = await http.post(Uri.parse(endpoint + '/api/a2a/send'), headers:{'content-type':'application/json','authorization':'Bearer '+token!}, body:jsonEncode({'envelope':envelope}));
    if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('AUREN A2A gateway returned '+response.statusCode.toString()+'.');
  }
}
