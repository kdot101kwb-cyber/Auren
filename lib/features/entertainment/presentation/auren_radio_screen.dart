import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'auren_audio_player_screen.dart';

class AurenRadioScreen extends StatefulWidget {
  const AurenRadioScreen({super.key});
  @override
  State<AurenRadioScreen> createState() => _AurenRadioScreenState();
}

class _AurenRadioScreenState extends State<AurenRadioScreen> {
  final _searchController = TextEditingController();
  String _country = '';
  String _tag = '';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _discovered = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _discover() async {
    setState(() { _loading = true; _error = null; });
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('searchAurenRadio');
      final response = await callable.call({
        'query': _searchController.text.trim(),
        'countryCode': _country,
        'tag': _tag,
        'limit': 30,
      });
      final raw = response.data is Map ? response.data['results'] : null;
      final results = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) setState(() => _discovered = results);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر اكتشاف المحطات الآن. جرّب مرة أخرى.';
          _discovered = const [];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openStream(Map<String, dynamic> station) async {
    final streamUrl = station['streamUrl']?.toString() ?? '';
    if (streamUrl.isEmpty) return;
    final item = AurenEntertainmentItem(
      id: 'radio_' + (station['stationUuid'] ?? station['name']).toString(),
      title: station['name']?.toString() ?? 'AUREN Radio',
      type: 'Radio',
      description: [
        station['country']?.toString() ?? '',
        station['language']?.toString() ?? '',
        station['tags']?.toString() ?? '',
      ].where((e) => e.trim().isNotEmpty).join(' • '),
      imageUrl: station['favicon']?.toString() ?? '',
      mediaUrl: streamUrl,
      mediaKind: 'audio',
      creatorId: '',
      channelId: '',
      country: station['country']?.toString() ?? '',
      language: station['language']?.toString() ?? '',
      artistName: station['name']?.toString() ?? '',
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = EntertainmentRepository();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Radio'),
        actions: [
          if (_country.isNotEmpty || _tag.isNotEmpty || _searchController.text.isNotEmpty)
            IconButton(tooltip: 'مسح الفلاتر', icon: const Icon(Icons.filter_alt_off_rounded), onPressed: () { _searchController.clear(); setState(() { _country = ''; _tag = ''; _discovered = const []; }); }),
          IconButton(
            tooltip: 'اكتشاف',
            onPressed: _loading ? null : _discover,
            icon: const Icon(Icons.travel_explore),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          _buildHero(context),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _discover(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ابحث عن محطة، دولة أو نوع موسيقى...',
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _country.isEmpty ? null : _country,
                  decoration: const InputDecoration(
                    labelText: 'الدولة',
                    prefixIcon: Icon(Icons.public),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'SD', child: Text('السودان')),
                    DropdownMenuItem(value: 'EG', child: Text('مصر')),
                    DropdownMenuItem(value: 'SA', child: Text('السعودية')),
                    DropdownMenuItem(value: 'AE', child: Text('الإمارات')),
                    DropdownMenuItem(value: 'TR', child: Text('تركيا')),
                    DropdownMenuItem(value: 'US', child: Text('USA')),
                    DropdownMenuItem(value: 'GB', child: Text('UK')),
                  ],
                  onChanged: (value) {
                    setState(() => _country = value ?? '');
                    _discover();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _tag.isEmpty ? null : _tag,
                  decoration: const InputDecoration(
                    labelText: 'النوع',
                    prefixIcon: Icon(Icons.music_note),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'news', child: Text('أخبار')),
                    DropdownMenuItem(value: 'music', child: Text('موسيقى')),
                    DropdownMenuItem(value: 'sports', child: Text('رياضة')),
                    DropdownMenuItem(value: 'talk', child: Text('Talk')),
                    DropdownMenuItem(value: 'culture', child: Text('ثقافة')),
                  ],
                  onChanged: (value) {
                    setState(() => _tag = value ?? '');
                    _discover();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _loading ? null : _discover,
            icon: _loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.radio),
            label: Text(_loading ? 'جاري اكتشاف المحطات...' : 'اكتشف Radio عالمي'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off),
                title: const Text('تعذر الاتصال بمصدر الراديو'),
                subtitle: Text(_error!),
                trailing: TextButton(onPressed: _discover, child: const Text('إعادة')),
              ),
            ),
          ],
          if (_discovered.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('محطات مباشرة (${_discovered.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ..._discovered.map((station) => Card(
              child: ListTile(
                leading: _stationImage(station),
                title: Text(station['name']?.toString() ?? 'Radio', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    station['country']?.toString() ?? '',
                    station['language']?.toString() ?? '',
                    station['tags']?.toString() ?? '',
                  ].where((e) => e.trim().isNotEmpty).join(' • '),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.play_circle_fill),
                onTap: () => _openStream(station),
              ),
            )),
          ],
          const SizedBox(height: 18),
          StreamBuilder<List<AurenEntertainmentItem>>(
            stream: repo.watchItems(type: 'Radio'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: const Text('تعذر تحميل محطات AUREN'),
                    subtitle: Text(snapshot.error.toString()),
                  ),
                );
              }
              final items = snapshot.data ?? const <AurenEntertainmentItem>[];
              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('لا توجد محطات مضافة إلى AUREN بعد. استخدم الاكتشاف للعثور على محطات مباشرة.'),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('محطات داخل AUREN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...items.map((item) => Card(
                    child: ListTile(
                      leading: item.imageUrl.isEmpty
                          ? const CircleAvatar(child: Icon(Icons.radio))
                          : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
                      title: Text(item.title),
                      subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: uid == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () => repo.save(uid, item.id),
                            ),
                      onTap: item.mediaUrl.isEmpty ? null : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)),
                      ),
                    ),
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stationImage(Map<String, dynamic> station) {
    final url = station['favicon']?.toString() ?? '';
    return url.isEmpty
        ? const CircleAvatar(child: Icon(Icons.radio))
        : CircleAvatar(backgroundImage: NetworkImage(url));
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Radio. Anywhere. Anytime.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
          SizedBox(height: 7),
          Text('أخبار • موسيقى • رياضة • ثقافة • محطات محلية وعالمية', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
