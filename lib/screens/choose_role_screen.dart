import 'package:flutter/material.dart';
import 'login_admin_screen.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'receptionist_auth_screen.dart';
import 'package:go_router/go_router.dart';

class ChooseRoleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('ChooseRoleScreen build appelé');

    // Vérifier l'URL et rediriger si c'est un lien réceptionniste (cette logique peut être simplifiée/déplacée vers GoRouter redirect)
    // Avec GoRouter, le redirector dans main.dart gère déjà l'URL initiale. Donc, cette logique ici devient moins critique pour l'accès initial.
    // Cependant, nous laissons une vérification basique ici pour les cas de navigation non-initiale si nécessaire, mais la principale est dans GoRouter redirect.
    if (kIsWeb) {
      final uri = Uri.base;
      final pathSegments = uri.pathSegments;
      final queryParameters = uri.queryParameters;

      final bool isConversationPath = pathSegments.length >= 2 && pathSegments[0] == 'conversation';
      final String? conversationIdFromUrl = isConversationPath ? pathSegments[1] : null;
      final String? role = queryParameters['role'];
      final String? receptionistName = queryParameters['receptionistName'];

      print('DEBUG ChooseRoleScreen: Vérification URL - path: ${uri.path}, role: $role, conversationId: $conversationIdFromUrl, receptionistName: $receptionistName');

      // La logique de redirection principale est désormais dans le redirector de GoRouter dans main.dart.
      // Si on arrive ici avec une URL réceptionniste, c'est que le redirector n'a pas fonctionné ou on arrive via une autre navigation.
      // On pourrait choisir de rediriger ici aussi par sécurité, mais idéalement, le redirector gère l'accès direct.
      // Pour l'instant, on s'assure juste que les boutons naviguent correctement avec go_router.
       if (isConversationPath && conversationIdFromUrl != null && conversationIdFromUrl.isNotEmpty && role == 'receptionist' && receptionistName != null && receptionistName.isNotEmpty) {
            print('DEBUG ChooseRoleScreen: URL réceptionniste détectée. Laissez GoRouter gérer ou rediriger manuellement si nécessaire.');
            // Potentiellement, naviguer vers la route d'authentification ici si on arrive via une route GoRouter qui ne la gère pas (moins probable avec le redirector).
            // context.go('/receptionniste-auth/$conversationIdFromUrl?receptionistName=${Uri.encodeComponent(receptionistName)}');
            // Retourner un indicateur pendant la redirection si on choisit de la faire ici
            // return Scaffold(body: Center(child: CircularProgressIndicator()));
       }
       print('DEBUG ChooseRoleScreen: Pas un lien réceptionniste direct (ou géré par GoRouter). Affichage des options.');
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
                  // Vider les infos client pour forcer la saisie à chaque fois
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('clientNom');
                  await prefs.remove('clientPrenom');
                  await prefs.remove('clientHotelId');
                  await prefs.remove('clientHotelName');
                  // Naviguer vers l'écran de chat client en utilisant go_router
                  context.go('/chat');
                },
                child: Text("Se connecter en tant que client"),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Naviguer vers l'écran de connexion admin en utilisant go_router
                  context.go('/admin-login');
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