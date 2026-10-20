import 'package:flutter/material.dart';

import '../../../services/auth/auth_service.dart';
import '../../talent/presentation/music_audio_lab.dart';

/// Workshop entry point reusing AUREN Music's existing recorder and analyzer.
/// It intentionally does not duplicate the underlying recording service.
class AurenAudioWorkshopScreen extends StatelessWidget {
  const AurenAudioWorkshopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (FirebaseAurenAuthService().currentUserId == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول لاستخدام Audio Workshop.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Audio Workshop')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('سجّل صوتك واستمع للتحليل الأولي للتردد والنوتة وقوة الإشارة. يستخدم هذا المسار مسجل AUREN Music الموجود بدلاً من إنشاء مسجل مكرر.'),
          SizedBox(height: 12),
          AurenMusicAudioLab(),
          SizedBox(height: 12),
          Text('هذه النسخة تعيد استخدام التسجيل والتحليل المحليين الموجودين. إدارة جلسات متكاملة وعلامات زمنية ومزامنة سحابية ما زالت بحاجة إلى استكمال.', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
