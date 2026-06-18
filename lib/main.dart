import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/auth_page.dart'; // On importe notre nouvelle vue

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const BionicSoulApp());
}

class BionicSoulApp extends StatelessWidget {
  const BionicSoulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bionic Soul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 61, 98, 161), // Ton bleu foncé
        scaffoldBackgroundColor: const Color.fromARGB(255, 240, 245, 255), // Ton fond clair
        useMaterial3: true,
      ),
      home: const AuthPage(),
    );
  }
}