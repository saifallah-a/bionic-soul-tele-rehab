import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_page.dart';

class ProthesisteDashboard extends StatelessWidget {
  const ProthesisteDashboard({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 247, 250),
      appBar: AppBar(
        title: const Text('Tableau de bord Clinique', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal, // Couleur médicale pour le docteur
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Derniers bilans IA des patients",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(
            // Le StreamBuilder écoute tous les "bilans" de tous les "users" en temps réel
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('bilans')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erreur de chargement : ${snapshot.error}", textAlign: TextAlign.center),
                  );
                }

                final bilans = snapshot.data?.docs ?? [];

                if (bilans.isEmpty) {
                  return const Center(
                    child: Text("Aucun bilan récent. Les patients vont bien ! 🎉", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: bilans.length,
                  itemBuilder: (context, index) {
                    final data = bilans[index].data() as Map<String, dynamic>;
                    
                    // --- NOUVEAU : Récupération de l'identité du patient ---
                    final String patientEmail = data['patientEmail'] ?? 'Email inconnu';
                    final String patientId = data['patientId'] ?? 'ID non spécifié';
                    // --------------------------------------------------------

                    final int douleur = data['niveau_douleur'] ?? 0;
                    final bool urgence = data['urgence'] ?? false;
                    final String resume = data['resume'] ?? 'Pas de résumé';
                    final String typeDouleur = data['type_douleur'] ?? 'Non précisé';
                    
                    // Formatage basique de la date
                    final Timestamp? timestamp = data['date'] as Timestamp?;
                    final String dateAffichee = timestamp != null 
                        ? "${timestamp.toDate().day}/${timestamp.toDate().month} à ${timestamp.toDate().hour}h${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                        : "Date inconnue";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      elevation: urgence ? 4 : 1, // L'ombre est plus forte si c'est urgent
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: urgence ? Colors.red.shade300 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- NOUVELLE SECTION : IDENTITÉ DU PATIENT ---
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.teal.shade50,
                                  child: const Icon(Icons.person, color: Colors.teal),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patientEmail, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                      ),
                                      Text(
                                        "ID Patient : $patientId", 
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis, // Coupe proprement si l'ID est trop long
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            // ----------------------------------------------

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      urgence ? Icons.warning_rounded : Icons.check_circle,
                                      color: urgence ? Colors.red : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      urgence ? "URGENCE DÉTECTÉE" : "État Stable",
                                      style: TextStyle(
                                        color: urgence ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(dateAffichee, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text("Synthèse de l'IA :", style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 5),
                            Text(resume, style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text("Symptôme : $typeDouleur", style: const TextStyle(fontSize: 13)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: urgence ? Colors.red.shade100 : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "Douleur : $douleur/10", 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: urgence ? Colors.red.shade900 : Colors.blue.shade900
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}