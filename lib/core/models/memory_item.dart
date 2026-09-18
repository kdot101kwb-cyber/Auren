class AurenMemoryItem {
  final String id, key, value;
  final bool enabled;
  final DateTime updatedAt;
  const AurenMemoryItem({required this.id,required this.key,required this.value,required this.enabled,required this.updatedAt});
  Map<String,dynamic> toMap()=>{'key':key,'value':value,'enabled':enabled,'updatedAt':updatedAt.toUtc().toIso8601String()};
  factory AurenMemoryItem.fromMap(String id,Map<String,dynamic> m)=>AurenMemoryItem(id:id,key:m['key']??'',value:m['value']??'',enabled:m['enabled']??true,updatedAt:DateTime.tryParse(m['updatedAt']??'')??DateTime.now());
}