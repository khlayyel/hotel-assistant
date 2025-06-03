// ==========================
// login_admin_screen.dart : Écran de connexion pour les administrateurs
// ==========================

// Importation de la librairie Flutter pour l'UI
import 'package:flutter/material.dart'; // Permet de créer des widgets visuels
// Importation de Firestore pour la vérification des identifiants admin
import 'package:cloud_firestore/cloud_firestore.dart'; // Accès à la base de données
// Importation de l'écran de gestion des hôtels (après connexion)
import 'gestion_hotels_screen.dart'; // Navigation après login
// Importation de l'écran de choix de rôle (pour retour)
import 'choose_role_screen.dart';

// Widget principal pour la connexion admin
class LoginAdminScreen extends StatefulWidget {
  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

// Classe d'état associée à LoginAdminScreen
class _LoginAdminScreenState extends State<LoginAdminScreen> {
  // Contrôleur pour le champ nom d'utilisateur
  final TextEditingController _usernameController = TextEditingController();
  // Contrôleur pour le champ mot de passe
  final TextEditingController _passwordController = TextEditingController();
  // Indique si la connexion est en cours
  bool _loading = false;
  // Message d'erreur à afficher
  String? _error;
  // Gère l'affichage/masquage du mot de passe
  bool _obscurePassword = true;

  // Méthode pour tenter la connexion admin
  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // Vérifie que les champs ne sont pas vides
    if (username.isEmpty || password.isEmpty) {
      setState(() { _error = "Veuillez remplir tous les champs."; _loading = false; });
      return;
    }

    try {
      // Recherche l'admin dans Firestore
      final query = await FirebaseFirestore.instance.collection('admins').where('username', isEqualTo: username).get();
      if (query.docs.isNotEmpty) {
        final adminDoc = query.docs.first;
        // Vérifie le mot de passe
        if (adminDoc.data()['password'] == password) {
          // Navigation vers la gestion des hôtels si succès
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => GestionHotelsScreen()),
          );
          setState(() { _loading = false; });
          return;
        }
      }
      setState(() { _error = "Identifiants incorrects."; });
    } catch (e) {
      setState(() { _error = "Erreur de connexion."; });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    // Scaffold fournit la structure de base de l'écran
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0d1a36), Color(0xFF1976d2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: BoxConstraints(maxWidth: isMobile ? 400 : 380),
                padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône admin
                    Icon(Icons.admin_panel_settings, size: 48, color: Color(0xFF0d1a36)),
                    SizedBox(height: 18),
                    // Titre
                    Text("Connexion Admin", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0d1a36))),
                    SizedBox(height: 30),
                    // Champ nom d'utilisateur
                    TextField(
                      controller: _usernameController,
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "Nom d'utilisateur",
                        prefixIcon: Icon(Icons.person, color: Color(0xFF0d1a36)),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Champ mot de passe
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF0d1a36)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF0d1a36)),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Affichage de l'erreur si besoin
                    if (_error != null)
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!, style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 18),
                    // Bouton de connexion
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0d1a36),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        child: _loading ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : Text("Se connecter"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 