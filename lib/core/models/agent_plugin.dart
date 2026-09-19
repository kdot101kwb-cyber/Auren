class AurenAgentPlugin {
 final String pluginId,name,version,entrypoint,sandbox;
 final List<String> capabilities;
 const AurenAgentPlugin({required this.pluginId,required this.name,required this.version,required this.entrypoint,required this.capabilities,required this.sandbox});
 factory AurenAgentPlugin.fromMap(Map<String,dynamic> m)=>AurenAgentPlugin(pluginId:m['pluginId'] as String???'',name:m['name'] as String???'',version:m['version'] as String???'1.0.0',entrypoint:m['entrypoint'] as String???'',capabilities:List<String>.from(m['capabilities'] as List???const []),sandbox:m['sandbox'] as String???'auren-isolated-v1');
}
