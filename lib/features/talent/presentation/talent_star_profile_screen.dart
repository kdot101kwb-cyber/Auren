import 'package:flutter/material.dart';
import '../../../core/models/talent.dart';
import '../../../core/models/user_profile.dart';
import '../../profile/presentation/public_profile_screen.dart';

class AurenTalentStarProfileScreen extends StatelessWidget {
  final AurenTalent talent;
  const AurenTalentStarProfileScreen({super.key, required this.talent});

  @override
  Widget build(BuildContext context) {
    final profile = AurenUserProfile(
      uid: talent.ownerId,
      displayName: talent.displayName,
      createdAt: DateTime.now(),
    );
    return AurenPublicProfileScreen(profile: profile, athlete: talent);
  }
}
