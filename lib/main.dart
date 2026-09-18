import 'package:flutter/material.dart';

void main() {
  runApp(const AurenApp());
}

class AurenApp extends StatelessWidget {
  const AurenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AUREN',
      theme: ThemeData.dark(useMaterial3: true),
      home: const AurenHome(),
    );
  }
}

class AurenHome extends StatelessWidget {
  const AurenHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN')),
      body: const Center(
        child: Text('Together, We Build.', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
