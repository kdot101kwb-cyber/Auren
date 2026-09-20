import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
class AurenPluginValidationResult {
 final bool valid; final Map<String,dynamic> manifest; final Map<String,dynamic> policy;
 const AurenPluginValidationResult({required this.valid,required this.manifest,required this.policy});
}
class AurenAgentPluginRepository {
 final FirebaseAuth _auth; final String endpoint;
 AurenAgentPluginRepository({FirebaseAuth? auth}):_auth=auth??FirebaseAuth.instance,endpoint=const String.fromEnvironment('AUREN_ACTION_EXECUTOR_URL');
 Future<AurenPluginValidationResult> validate(Map<String,dynamic> manifest) async {
  if(endpoint.isEmpty) throw StateError('AUREN_ACTION_EXECUTOR_URL is not configured.');
  final user=_auth.currentUser; if(user==null) throw StateError('User is not authenticated.');
  final token=await user.getIdToken();
  final response=await http.post(Uri.parse(endpoint+'/api/agents/plugins/validate'),headers:{'content-type':'application/json','authorization':'Bearer '+token!},body:jsonEncode({'manifest':manifest}));
  final data=jsonDecode(response.body) as Map<String,dynamic>;
  if(response.statusCode<200||response.statusCode>=300) throw StateError(data['error'] as String? ?? 'Plugin validation failed.');
  return AurenPluginValidationResult(valid:data['valid'] as bool? ?? false,manifest:Map<String,dynamic>.from(data['manifest'] as Map? ?? const {}),policy:Map<String,dynamic>.from(data['policy'] as Map? ?? const {}));
 }
  Future<void> installValidated({required String pluginId, required String name, required String version, required List<String> capabilities}) async {
    if(endpoint.isEmpty) throw StateError('AUREN_ACTION_EXECUTOR_URL is not configured.');
    final user=_auth.currentUser; if(user==null) throw StateError('User is not authenticated.');
    final token=await user.getIdToken();
    final response=await http.post(Uri.parse(endpoint+'/api/agents/plugins/install'),headers:{'content-type':'application/json','authorization':'Bearer '+token!},body:jsonEncode({'pluginId':pluginId,'name':name,'version':version,'capabilities':capabilities}));
    if(response.statusCode<200||response.statusCode>=300){final data=jsonDecode(response.body) as Map<String,dynamic>;throw StateError(data['error'] as String? ?? 'Plugin installation failed.');}
  }
  Future<void> recordInvocation({required String pluginId,required String action,Map<String,dynamic> payload=const {}}) async {
    if(endpoint.isEmpty) throw StateError('AUREN_ACTION_EXECUTOR_URL is not configured.');
    final user=_auth.currentUser; if(user==null) throw StateError('User is not authenticated.');
    final token=await user.getIdToken();
    final response=await http.post(Uri.parse(endpoint+'/api/agents/plugins/invoke'),headers:{'content-type':'application/json','authorization':'Bearer '+token!},body:jsonEncode({'pluginId':pluginId,'action':action,'payload':payload}));
    if(response.statusCode<200||response.statusCode>=300){final data=jsonDecode(response.body) as Map<String,dynamic>;throw StateError(data['error'] as String? ?? 'Plugin invocation failed.');}
  }
}