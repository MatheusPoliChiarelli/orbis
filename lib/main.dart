import 'package:flutter/material.dart';

void main() {
  runApp(const OrbisApp());
}

class OrbisApp extends StatelessWidget {
  const OrbisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbis',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Orbis'),
        ),
      ),
    );
  }
}