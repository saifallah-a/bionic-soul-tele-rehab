import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_dashboard.dart';
import 'prothesiste_dashboard.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      _showMessage(context, "Veuillez remplir tous les champs", isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Authentification Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userType = userData['userType'] ?? 'patient';
          
          _showMessage(context, "Connecté avec succès !");
          
          if (!mounted) return; // Sécurité Flutter
          
          if (userType == 'prothesiste') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProthesisteDashboard()),
            );
          } else {
            // Par défaut, c'est un patient
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PatientDashboard()),
            );
          }
        } else {
            _showMessage(context, "Erreur : Profil introuvable dans la base de données", isError: true);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Erreur de connexion";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = "Utilisateur ou mot de passe incorrect";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Format d'email invalide";
      }
      _showMessage(context, errorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 96, 177, 215),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(9.0), // Ajuste ce chiffre si le logo est trop grand/petit
                      child: Image.asset(
                        'assets/icons/logo_bionic.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain, 
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text("Connexion", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 5),
              const Text("Espace clinique Bionic Soul", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 61, 98, 161),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Se connecter", style: TextStyle(fontSize: 16)),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("Bionic Soul 2026", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
