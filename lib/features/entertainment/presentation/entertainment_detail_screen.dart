import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenEntertainmentDetailScreen extends StatelessWidget {
  final String itemId;
  const AurenEntertainmentDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final repo = EntertainmentRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Entertainment')),
      body: StreamBuilder<AurenEntertainmentItem?>(
        stream: repo.watchItem(itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final item = snapshot.data;
          if (item == null) return const Center(child: Text('هذا المحتوى غير متاح حالياً.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (item.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(item.imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Center(child: Icon(Icons.broken_image_outlined, size: 48))))),
                )
              else
                Container(height: 210, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xff4527a0), Color(0xff1565c0), Color(0xffad1457)])), child: const Center(child: Icon(Icons.play_circle_outline, size: 72))),
              const SizedBox(height: 18),
              Text(item.type.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: 'أريد معرفة المزيد عن ' + item.title + '، واقترح لي محتوى مشابهًا له.'))),
                icon: const Icon(Icons.auto_awesome), label: const Text('اسأل AUREN عنه'),
              ),
              if (uid != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: () => repo.save(uid, item.id), icon: const Icon(Icons.bookmark_add_outlined), label: const Text('حفظ للمشاهدة لاحقاً')),
              ],
            ],
          );
        },
      ),
    );
  }
}
