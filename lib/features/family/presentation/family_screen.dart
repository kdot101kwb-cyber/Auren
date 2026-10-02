import 'package:flutter/material.dart';

class AurenFamilyScreen extends StatelessWidget {
  const AurenFamilyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Family')),
    body: ListView(padding: const EdgeInsets.all(16), children: const [
      Card(child: ListTile(leading: Icon(Icons.family_restroom), title: Text('Family Hub'), subtitle: Text('مساحة الأسرة للأعضاء والأهداف المشتركة وصندوق الأسرة.'))),
      SizedBox(height: 12),
      Card(child: ListTile(leading: Icon(Icons.savings_outlined), title: Text('Family Pot'), subtitle: Text('إدارة صندوق الأسرة ومتابعة الحركات المالية المشتركة.'))),
    ]),
  );
}