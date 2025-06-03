// ==========================
// receptionist_auth_screen.dart : Authentification du réceptionniste avant accès au chat
// ==========================

// Importation de la librairie Flutter pour l'UI
import 'package:flutter/material.dart'; // Permet de créer des widgets visuels
// Importation de Firestore pour la vérification des identifiants
import 'package:cloud_firestore/cloud_firestore.dart'; // Accès à la base de données
// Importation de l'écran de chat réceptionniste
import 'receptionist_screen.dart'; // Navigation après authentification
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

// Widget principal pour l'authentification du réceptionniste
class ReceptionistAuthScreen extends StatefulWidget {
  // Identifiant de la conversation à rejoindre
  final String conversationId;
  // Nom du réceptionniste à authentifier
  final String receptionistName;

  const ReceptionistAuthScreen({
    Key? key,
    required this.conversationId,
    required this.receptionistName,
  }) : super(key: key);

  @override
  _ReceptionistAuthScreenState createState() => _ReceptionistAuthScreenState();
}

// Classe d'état associée à ReceptionistAuthScreen
class _ReceptionistAuthScreenState extends State<ReceptionistAuthScreen> {
  // Contrôleur pour le champ mot de passe
  final TextEditingController _passwordController = TextEditingController();
  // Indique si l'authentification est en cours
  bool _isLoading = false;
  // Message d'erreur à afficher
  String? _error;
  // Gère l'affichage/masquage du mot de passe
  bool _obscurePassword = true;

  Future<String> encryptPassword(String password) async {
    final response = await http.post(
      Uri.parse(Environment.apiBaseUrl + '/encrypt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['encrypted'];
    } else {
      throw Exception('Erreur de chiffrement');
    }
  }

  Future<String> decryptPassword(String encrypted) async {
    final response = await http.post(
      Uri.parse(Environment.apiBaseUrl + '/decrypt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'encrypted': encrypted}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['decrypted'];
    } else {
      throw Exception('Erreur de déchiffrement: ${response.body}');
    }
  }

  // Méthode pour authentifier le réceptionniste
  Future<void> _authenticate() async {
    // Vérifie que le champ mot de passe n'est pas vide
    if (_passwordController.text.isEmpty) {
      setState(() {
        _error = "Veuillez entrer votre mot de passe";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer le réceptionniste depuis Firestore
      final receptionistQuery = await FirebaseFirestore.instance
          .collectionGroup('receptionists')
          .where('name', isEqualTo: widget.receptionistName)
          .get();

      if (receptionistQuery.docs.isNotEmpty) {
        final receptionistDoc = receptionistQuery.docs.first;
        final receptionistData = receptionistDoc.data();
        final storedEncryptedPassword = receptionistData['password'];

        if (storedEncryptedPassword != null && storedEncryptedPassword.isNotEmpty) {
          try {
            // Déchiffre le mot de passe stocké et compare-le au mot de passe saisi
            final decryptedStoredPassword = await decryptPassword(storedEncryptedPassword);
            if (decryptedStoredPassword == _passwordController.text) {
              // Authentification réussie : navigation vers l'écran de chat réceptionniste
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceptionistScreen(
                    conversationId: widget.conversationId,
                    receptionistName: widget.receptionistName,
                  ),
                ),
              );
            } else {
              setState(() {
                _error = "Mot de passe incorrect";
                _isLoading = false;
              });
            }
          } catch (e) {
            print('Erreur de déchiffrement lors de l\'authentification réceptionniste : $e');
            setState(() {
              _error = "Erreur d\'authentification ou mot de passe incorrect";
              _isLoading = false;
            });
          }
        } else {
           setState(() {
            _error = "Mot de passe manquant dans la base de données";
            _isLoading = false;
           });
        }
      } else {
        setState(() {
          _error = "Réceptionniste non trouvé";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Une erreur est survenue lors de l\'authentification.";
        _isLoading = false;
      });
      print('Erreur d\'authentification: $e');
    }
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
        child: SafeArea(
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
                      // Icône réceptionniste
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color(0xFF0d1a36),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.headset_mic,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 28),
                      // Titre
                      Text(
                        "Authentification Réceptionniste",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0d1a36),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      // Affichage du nom du réceptionniste
                      Text(
                        widget.receptionistName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF0d1a36),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      // Champ mot de passe
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Mot de passe",
                          hintStyle: TextStyle(color: Color(0xFF1976d2)),
                          prefixIcon: Icon(Icons.lock, color: Color(0xFF0d1a36)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Color(0xFF1976d2),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Color(0xFF0d1a36), width: 1.2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 18),
                      // Affichage de l'erreur si besoin
                      if (_error != null)
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFF1976d2).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFF1976d2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Color(0xFF1976d2)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Color(0xFF1976d2), fontWeight: FontWeight.w600),
                                ),
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
                          onPressed: _isLoading ? null : _authenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0d1a36),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text("Se connecter"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Libère le contrôleur de texte
    _passwordController.dispose();
    super.dispose();
  }
} 