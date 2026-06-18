import 'package:flutter/material.dart';
import 'dart:convert'; // Indispensable pour lire le JSON
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Indispensable pour la base de données
import 'auth_page.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  static const String _apiKey = 'GEMINI_API_KEY'; 
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      // --- NOUVEAU PROMPT ENGINEERING AVANCÉ ---
      systemInstruction: Content.system(
        "Tu es l'assistant médical bienveillant de l'application Bionic Soul. "
        "Ton rôle est d'écouter un patient amputé et d'évaluer son état avec sa prothèse. "
        "Tu dois essayer d'obtenir subtilement ces informations : "
        "1. Le niveau de douleur (sur 10). "
        "2. Le type de gêne (ex: frottement, lourdeur, douleur fantôme, rougeur). "
        "3. Le confort général et s'il arrive à porter la prothèse toute la journée. "
        "RÈGLE D'OR : Si le patient ne donne pas ces infos, pose-lui des questions courtes et douces "
        "pour l'orienter. Ne le force jamais s'il ne veut pas répondre. Sois toujours très empathique, "
        "professionnel et rassurant. Fais des réponses courtes adaptées à un chat mobile."
        "si le patient parle en dialecte tunisien  ou n importe qu elle langue repond avec son meme langage "
      ),
    );
    
    _chatSession = _model.startChat();
    
    _messages.add({
      'role': 'bot', 
      'text': '🤖 Bonjour ! Comment vous sentez-vous aujourd\'hui avec votre prothèse ?'
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    
    setState(() {
      _messages.add({'role': 'user', 'text': '👤 $text'});
      _isLoading = true;
    });

    try {
      final response = await _chatSession.sendMessage(Content.text(text));
      
      setState(() {
        final reponsePropre = response.text?.replaceAll('**', '') ?? "Erreur de réponse";
        _messages.add({'role': 'bot', 'text': '🤖 $reponsePropre'});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': '🤖 Le serveur est surchargé, réessayez dans un instant...'});
      });
      print("Erreur Gemini : $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- NOUVELLE FONCTION : GÉNÉRER ET ENVOYER LE BILAN ---
  Future<void> _genererBilanEtTerminer() async {
    if (_messages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous devez d'abord discuter avec l'assistant.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Compilation de la conversation
      String historique = "Voici la transcription d'une discussion avec un patient :\n";
      for (var m in _messages) {
        historique += "${m['role']}: ${m['text']}\n";
      }
      
      // 2. Prompt d'extraction JSON
      historique += "\nAnalyse cette conversation et renvoie UNIQUEMENT un objet JSON valide avec ces clés exactes : "
          "'niveau_douleur' (entier de 0 à 10, mets 0 si non précisé), "
          "'type_douleur' (chaîne courte, ex: 'Frottement', 'Aucune', 'Fantôme'), "
          "'resume' (chaîne d'une phrase résumant l'état), "
          "'urgence' (booléen true si la douleur est > 6 ou s'il y a une blessure grave, sinon false). "
          "Ne mets aucune balise markdown (pas de ```json), juste le texte JSON brut.";

      // 3. Appel à Gemini
      final response = await _chatSession.sendMessage(Content.text(historique));
      
      // 4. Nettoyage et Parsing du JSON
      final jsonString = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? "{}";
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // 5. Sauvegarde dans Firebase Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('bilans').add({
          // --- AJOUT DE L'IDENTITÉ DU PATIENT (DÉNORMALISATION) ---
          'patientId': user.uid,
          'patientEmail': user.email ?? 'Email inconnu',
          // --------------------------------------------------------
          'niveau_douleur': data['niveau_douleur'] ?? 0,
          'type_douleur': data['type_douleur'] ?? 'Non précisé',
          'resume': data['resume'] ?? 'Résumé indisponible',
          'urgence': data['urgence'] ?? false,
          'date': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bilan analysé et envoyé au prothésiste ! ✅"), backgroundColor: Colors.green),
      );

    } catch (e) {
      print("Erreur d'analyse IA ou JSON : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Réseau surchargé. Impossible de finaliser le bilan pour le moment."), 
          backgroundColor: Colors.red
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 245, 255),
      appBar: AppBar(
        title: const Text('Bionic Agent'),
        backgroundColor: const Color.fromARGB(255, 61, 98, 161),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _genererBilanEtTerminer,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text("Terminer", style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final isUser = _messages[i]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      _messages[i]['text']!,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Décrivez votre état...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 61, 98, 161),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}