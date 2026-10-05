import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/safety/offline_safety_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenOfflineSafetyScreen extends StatefulWidget {
  const AurenOfflineSafetyScreen({super.key});

  @override
  State<AurenOfflineSafetyScreen> createState() => _AurenOfflineSafetyScreenState();
}

class _AurenOfflineSafetyScreenState extends State<AurenOfflineSafetyScreen> {
  String city = '';
  String country = '';

  void _area() {
    final cityController = TextEditingController(text: city);
    final countryController = TextEditingController(text: country);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('منطقة الرحلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'المدينة'),
            ),
            TextField(
              controller: countryController,
              decoration: const InputDecoration(labelText: 'الدولة'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                city = cityController.text.trim();
                country = countryController.text.trim();
              });
              Navigator.pop(ctx);
              cityController.dispose();
              countryController.dispose();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _places(String uid) {
    final service = AurenOfflineSafetyService.instance;

    return StreamBuilder<List<AurenSafetyPlace>>(
      stream: service.watchPlaces(city: city, country: country),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView(
            children: snapshot.data!
                .map(
                  (place) => ListTile(
                    leading: const Icon(Icons.emergency_outlined),
                    title: Text(place.name),
                    subtitle: Text(
                      '${place.type} • ${place.city}, ${place.country}',
                    ),
                  ),
                )
                .toList(),
          );
        }

        return FutureBuilder<List<AurenSafetyPlace>>(
          future: service.readCachedPlaces(city: city, country: country),
          builder: (context, cache) {
            if (cache.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final places = cache.data ?? const <AurenSafetyPlace>[];
            if (places.isEmpty) {
              return Center(
                child: Text(
                  snapshot.hasError
                      ? 'لا توجد بيانات محلية محفوظة لهذه المنطقة.'
                      : 'تحميل نقاط الأمان...',
                ),
              );
            }

            return ListView(
              children: [
                const ListTile(
                  leading: Icon(Icons.offline_pin_outlined),
                  title: Text('نقاط أمان محفوظة محلياً'),
                  subtitle: Text('تعمل بدون اتصال بالإنترنت'),
                ),
                ...places.map(
                  (place) => ListTile(
                    leading: const Icon(Icons.emergency_outlined),
                    title: Text(place.name),
                    subtitle: Text(
                      '${place.type} • ${place.city}, ${place.country}',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _routes(String uid) {
    final service = AurenOfflineSafetyService.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchRoutes(uid),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          service.cacheRoutes(uid, snapshot.data!);
          final routes = snapshot.data!.docs;

          if (routes.isEmpty) {
            return const SizedBox.shrink();
          }

          return Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.route_outlined),
                  title: Text('المسارات المحفوظة'),
                  subtitle: Text('متاحة للرجوع إليها عند ضعف الاتصال.'),
                ),
                ...routes.take(10).map((doc) {
                  final data = doc.data();
                  final points = data['points'];
                  final pointCount = points is List ? points.length : 0;

                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.navigation_outlined),
                    title: Text(data['name']?.toString() ?? 'مسار'),
                    subtitle: Text('نقاط المسار: $pointCount'),
                  );
                }),
              ],
            ),
          );
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: service.readCachedRoutes(uid),
          builder: (context, cache) {
            final routes = cache.data ?? const <Map<String, dynamic>>[];

            if (routes.isEmpty) {
              return const SizedBox.shrink();
            }

            return Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.offline_pin_outlined),
                    title: Text('المسارات المحفوظة محلياً'),
                    subtitle: Text('تعمل بدون اتصال بالإنترنت.'),
                  ),
                  ...routes.take(10).map((route) {
                    final points = route['points'];
                    final pointCount = points is List ? points.length : 0;

                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.navigation_outlined),
                      title: Text(route['name']?.toString() ?? 'مسار'),
                      subtitle: Text('نقاط المسار: $pointCount'),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Navigation + Safety'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessengerScreen(
                  initialPrompt:
                      'ساعدني في خطة تنقل آمنة عند ضعف الإنترنت، واذكر نقاط الطوارئ المهمة في المنطقة.',
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _area,
            icon: const Icon(Icons.location_city),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('سجّل الدخول لاستخدام الأمان.'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.offline_bolt_outlined),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AUREN يحفظ آخر نقاط الأمان والمسارات على الجهاز للاستخدام عند ضعف الاتصال.',
                        ),
                      ),
                    ],
                  ),
                ),
                _routes(uid),
                Expanded(child: _places(uid)),
              ],
            ),
    );
  }
}
