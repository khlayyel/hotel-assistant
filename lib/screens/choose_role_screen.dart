import 'package:flutter/material.dart';
import 'login_admin_screen.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ChooseRoleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('ChooseRoleScreen build appelé');
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Bienvenue !", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  // Vérifier si l'URL indique un rôle de réceptionniste
                  if (kIsWeb) {
                    final uri = Uri.base;
                    final role = uri.queryParameters['role'];
                    if (role == 'receptionniste' || role == 'receptionist') {
                       // Si c'est un lien réceptionniste, ne pas naviguer ici.
                       // L'authentification est déjà gérée par le routage initial.
                       print('Tentative de connexion client sur un lien réceptionniste. Ignoré.');
                       return; // Sortir de la fonction onPressed
                    }
                  }

                  // Si ce n'est pas un lien réceptionniste (ou sur mobile),
                  // procéder à la connexion client normale.

                  // Vider les infos client pour forcer la saisie à chaque fois
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('clientNom');
                  await prefs.remove('clientPrenom');
                  await prefs.remove('clientHotelId');
                  await prefs.remove('clientHotelName');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreen()),
                  );
                },
                child: Text("Se connecter en tant que client"),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginAdminScreen()),
                  );
                },
                child: Text("Se connecter en tant qu'admin"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  backgroundColor: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 