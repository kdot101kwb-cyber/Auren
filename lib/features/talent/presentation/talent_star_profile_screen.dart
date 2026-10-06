import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/talent.dart';
import '../../../core/models/user_profile.dart';
import '../../profile/presentation/public_profile_screen.dart';

class AurenTalentStarProfileScreen extends StatelessWidget {
  final AurenTalent talent;
  const AurenTalentStarProfileScreen({super.key, required this.talent});

  Future<AurenUserProfile> _loadProfile() async {
    final fallback = AurenUserProfile(
      uid: talent.ownerId,
      displayName: talent.displayName,
      createdAt: DateTime.now(),
    );
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(talent.ownerId).get();
      final data = snap.data();
      if (data == null) return fallback;
      final createdRaw = data['createdAt'];
      final createdAt = createdRaw is Timestamp
          ? createdRaw.toDate()
          : DateTime.tryParse(createdRaw?.toString() ?? '') ?? fallback.createdAt;
      return AurenUserProfile(
        uid: talent.ownerId,
        displayName: (data['displayName'] ?? talent.displayName).toString(),
        photoUrl: (data['photoUrl'] ?? '').toString().trim().isEmpty
            ? null
            : data['photoUrl'].toString(),
        createdAt: createdAt,
      );
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AurenUserProfile>(
      future: _loadProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return AurenPublicProfileScreen(profile: profile, athlete: talent);
      },
    );
  }
}
