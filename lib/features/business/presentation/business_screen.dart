import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/presentation/adaptive_profile_surface.dart';
import '../../../services/social/adaptive_profile_service.dart';
import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_repository.dart';
import 'business_detail_screen.dart';
import 'saved_businesses_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';
class AurenBusinessScreen extends StatefulWidget{const AurenBusinessScreen({super.key});@override State<AurenBusinessScreen> createState()=>_AurenBusinessScreenState();}
_AUREN_PLACEHOLDER_