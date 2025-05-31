import 'package:flutter/material.dart';
import 'login_admin_screen.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'receptionist_auth_screen.dart';

class ChooseRoleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('ChooseRoleScreen build appelé');

    // Vérifier l'URL et rediriger si c'est un lien réceptionniste
    if (kIsWeb) {
      final uri = Uri.base;
      final pathSegments = uri.pathSegments;
      final queryParameters = uri.queryParameters;

      final bool isConversationPath = pathSegments.length >= 2 && pathSegments[0] == 'conversation';
      final String? conversationIdFromUrl = isConversationPath ? pathSegments[1] : null;
      final String? role = queryParameters['role'];
      final String? receptionistName = queryParameters['receptionistName'];

      print('DEBUG ChooseRoleScreen: Vérification URL - path: ${uri.path}, role: $role, conversationId: $conversationIdFromUrl, receptionistName: $receptionistName');

      // Si c'est l'URL de la conversation réceptionniste avec les paramètres requis, rediriger
      if (isConversationPath && conversationIdFromUrl != null && conversationIdFromUrl.isNotEmpty && role == 'receptionist' && receptionistName != null && receptionistName.isNotEmpty) {
        print("DEBUG ChooseRoleScreen: Rôle réceptionniste détecté dans l'URL. Redirection vers l'authentification...");
        // Utiliser addPostFrameCallback pour déclencher la navigation après le build
        WidgetsBinding.instance.addPostFrameCallback((_) {
           Navigator.pushReplacementNamed(
             context,
             '/receptionniste-auth', // Nom de la route définie dans main.dart
             arguments: {
               'conversationId': conversationIdFromUrl,
               'receptionistName': receptionistName,
             },
           );
        });
        // Retourner un conteneur vide ou un indicateur de chargement pendant la redirection
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      }
       print('DEBUG ChooseRoleScreen: Pas un lien réceptionniste direct. Affichage des options.');
    }

    // Reste du build si ce n'est pas une redirection ou si ce n'est pas sur le web
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