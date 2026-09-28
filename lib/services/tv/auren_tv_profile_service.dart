import 'package:shared_preferences/shared_preferences.dart';

class AurenTvProfile {
  final String id;
  final String name;
  const AurenTvProfile({required this.id, required this.name});
}

class AurenTvProfileService {
  static final AurenTvProfileService instance = AurenTvProfileService._();
  AurenTvProfileService._();
  static const _profilesKey = 'auren_tv_profiles_v1';
  static const _activeKey = 'auren_tv_active_profile_v1';

  Future<List<AurenTvProfile>> profiles() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_profilesKey) ?? const ['main|Main'];
    return raw.map((e) {
      final i=e.indexOf('|');
      if(i<=0) return AurenTvProfile(id:e,name:e);
      return AurenTvProfile(id:e.substring(0,i),name:e.substring(i+1));
    }).where((e)=>e.id.isNotEmpty&&e.name.isNotEmpty).toList();
  }
  Future<String> activeProfileId() async {
    final p=await SharedPreferences.getInstance();
    return p.getString(_activeKey)??'main';
  }
  Future<void> saveProfile(String name) async {
    final clean=name.trim(); if(clean.isEmpty)return;
    final p=await SharedPreferences.getInstance();
    final list=p.getStringList(_profilesKey)??<String>['main|Main'];
    final id=clean.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'),'_').replaceAll(RegExp(r'^_|_$'),'');
    final safeId=id.isEmpty?'profile_${DateTime.now().millisecondsSinceEpoch}':id;
    if(!list.any((e)=>e.startsWith('$safeId|'))){list.add('$safeId|$clean'); await p.setStringList(_profilesKey,list);}
  }
  Future<void> setActiveProfile(String id) async {
    final p=await SharedPreferences.getInstance(); await p.setString(_activeKey,id);
  }
  Future<void> deleteProfile(String id) async {
    if(id=='main')return;
    final p=await SharedPreferences.getInstance();
    final list=p.getStringList(_profilesKey)??<String>['main|Main'];
    list.removeWhere((e)=>e.startsWith('$id|')); await p.setStringList(_profilesKey,list);
    if((p.getString(_activeKey)??'main')==id) await p.setString(_activeKey,'main');
  }
}