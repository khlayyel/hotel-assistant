// ==========================
// choose_role_screen.dart : Écran de choix du rôle utilisateur (client ou admin)
// ==========================

// Importation de la librairie Flutter pour l'UI
import 'package:flutter/material.dart'; // Permet de créer des widgets visuels
// Importation de l'écran de connexion admin
import 'login_admin_screen.dart'; // Pour naviguer vers la connexion admin
// Importation du fichier principal (pour accéder à ChatScreen)
import '../main.dart';
// Importation pour la gestion des préférences locales
import 'package:shared_preferences/shared_preferences.dart';

// Widget principal qui permet à l'utilisateur de choisir son rôle
class ChooseRoleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('ChooseRoleScreen build appelé'); // Log pour debug
    // Scaffold fournit la structure de base de l'écran (fond, body, etc.)
    return Scaffold(
      body: Container(
        width: double.infinity, // Prend toute la largeur
        height: double.infinity, // Prend toute la hauteur
        decoration: BoxDecoration(
          // Dégradé de couleurs pour le fond
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0d1a36), Color(0xFF1976d2)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400), // Largeur max pour l'UI
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centre verticalement
              children: [
                // Titre de bienvenue
                Text("Bienvenue !", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 40), // Espace
                // Bouton pour se connecter en tant que client
                ElevatedButton(
                  onPressed: () async {
                    // Vider les infos client pour forcer la saisie à chaque fois
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('clientNom');
                    await prefs.remove('clientPrenom');
                    await prefs.remove('clientHotelId');
                    await prefs.remove('clientHotelName');
                    // Navigue vers l'écran de chat client
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatScreen()),
                    );
                  },
                  child: Text("Se connecter en tant que client"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    backgroundColor: Color(0xFF0d1a36),
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20), // Espace
                // Bouton pour se connecter en tant qu'admin
                ElevatedButton(
                  onPressed: () {
                    // Navigue vers l'écran de connexion admin (remplace l'écran actuel)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginAdminScreen()),
                    );
                  },
                  child: Text("Se connecter en tant qu'admin"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    backgroundColor: Color(0xFF1976d2),
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 