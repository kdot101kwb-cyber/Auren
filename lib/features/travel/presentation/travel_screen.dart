import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/travel/travel_repository.dart';
import '../../../core/models/travel.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENTravelScreen extends StatelessWidget {
  const AurenAURENTravelScreen({super.key});
  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid; final repo = TravelRepository();
    return Scaffold(appBar: AppBar(title: const Text('AUREN Travel')), body: StreamBuilder<List<AurenPlace>>(stream: repo.watchPlaces(), builder: (context, snapshot) {
      if (snapshot.hasError) return _error(snapshot.error);
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      final places = snapshot.data ?? const <AurenPlace>[];
      return ListView(padding: const EdgeInsets.all(16), children: [
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.explore, size: 34), title: Text('Discover the world', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), subtitle: Text('وجهات، إقامة، ثقافة، وتنقل في مكان واحد.')),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'خطط لي رحلة مناسبة حسب ميزانيتي واهتماماتي.'))), icon: const Icon(Icons.auto_awesome), label: const Text('AI Trip'))),
          const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: uid == null ? null : () => _newTrip(context, repo, uid), icon: const Icon(Icons.add), label: const Text('My Trip'))),
        ]),
        const SizedBox(height: 16), const Text('Places', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (places.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد أماكن منشورة حالياً.'))),
        ...places.map((p) => Card(child: ListTile(
          leading: p.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.place)) : CircleAvatar(backgroundImage: NetworkImage(p.imageUrl)),
          title: Text(p.name), subtitle: Text('${p.city}, ${p.country}\n${p.description}'), isThreeLine: true,
          trailing: uid == null ? null : IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () => repo.savePlace(uid, p.id)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: 'اكتشف لي ${p.name} في ${p.city}, ${p.country} وخطط لي زيارة مناسبة.'))),
        ))),
        if (uid != null) StreamBuilder<List<AurenTrip>>(stream: repo.watchMyTrips(uid), builder: (context, s) {
          final trips = s.data ?? const <AurenTrip>[]; if (trips.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 16), const Text('My Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), ...trips.map((t) => Card(child: ListTile(leading: const Icon(Icons.luggage), title: Text(t.title), subtitle: Text(t.destination))))]);
        }),
      ]);
    }));
  }
  Future<void> _newTrip(BuildContext context, TravelRepository repo, String uid) async {
    final title = TextEditingController(), destination = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('New Trip'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'Trip name')), TextField(controller: destination, decoration: const InputDecoration(labelText: 'Destination'))]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Create'))]));
    if (ok == true && title.text.trim().isNotEmpty && destination.text.trim().isNotEmpty) await repo.createTrip(uid: uid, title: title.text, destination: destination.text);
  }
}
Widget _error(Object? e) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('تعذر تحميل بيانات السفر. $e')));
