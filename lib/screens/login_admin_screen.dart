import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gestion_hotels_screen.dart';

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
      final doc = await FirebaseFirestore.instance.collection('admins').doc(username).get();
      if (doc.exists && doc.data()?['username'] == username && doc.data()?['password'] == password) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GestionHotelsScreen()),
        );
      } else {
        setState(() { _error = "Identifiants incorrects."; });
      }
    } catch (e) {
      setState(() { _error = "Erreur de connexion."; });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connexion Admin")),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Connexion Admin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: "Nom d'utilisateur"),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Mot de passe"),
                obscureText: true,
              ),
              SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading ? CircularProgressIndicator() : Text("Se connecter"),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 