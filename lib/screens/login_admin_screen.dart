import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gestion_hotels_screen.dart';
import 'choose_role_screen.dart';

class LoginAdminScreen extends StatefulWidget {
  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() { _error = "Veuillez remplir tous les champs."; _loading = false; });
      return;
    }

    try {
      final query = await FirebaseFirestore.instance.collection('admins').where('username', isEqualTo: username).get();
      if (query.docs.isNotEmpty) {
        final adminDoc = query.docs.first;
        if (adminDoc.data()['password'] == password) {
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
                    Icon(Icons.admin_panel_settings, size: 48, color: Color(0xFF0d1a36)),
                    SizedBox(height: 18),
                    Text("Connexion Admin", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0d1a36))),
                    SizedBox(height: 30),
                    TextField(
                      controller: _usernameController,
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "Nom d'utilisateur",
                        prefixIcon: Icon(Icons.person, color: Color(0xFF0d1a36)),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF0d1a36)),
                      ),
                    ),
                    SizedBox(height: 24),
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