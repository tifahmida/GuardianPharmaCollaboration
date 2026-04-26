import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://olurcwfhisqvllqhmkmz.supabase.co',
    anonKey: 'sb_publishable_KrJ_5b0NGYFmnhOBlOPVtA_PXPjBDzP',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(), // 🔥 THIS IS THE KEY CHANGE
    );
  }
}
