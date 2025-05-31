import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConversationRedirectScreen extends StatefulWidget {
  const ConversationRedirectScreen({Key? key}) : super(key: key);

  @override
  _ConversationRedirectScreenState createState() => _ConversationRedirectScreenState();
}

class _ConversationRedirectScreenState extends State<ConversationRedirectScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirect();
    });
  }

  void _redirect() {
    final goRouterState = GoRouterState.of(context);
    final conversationId = goRouterState.pathParameters['conversationId'];
    final role = goRouterState.uri.queryParameters['role'];
    final receptionistName = goRouterState.uri.queryParameters['receptionistName'];
    final hotelId = goRouterState.uri.queryParameters['hotelId'];

    print('DEBUG ConversationRedirectScreen: Redirection appelée. conversationId: $conversationId, role: $role, receptionistName: $receptionistName, hotelId: $hotelId');

    // Vérifier si c'est bien un lien réceptionniste et si les paramètres essentiels sont présents
    if (conversationId != null && conversationId.isNotEmpty && role == 'receptionist' && receptionistName != null && receptionistName.isNotEmpty && hotelId != null && hotelId.isNotEmpty) {
      // Rediriger vers l'écran d'authentification du réceptionniste avec tous les paramètres
      context.go('/receptionniste-auth/$conversationId?receptionistName=${Uri.encodeComponent(receptionistName)}&hotelId=${Uri.encodeComponent(hotelId)}');
    } else if (conversationId != null && conversationId.isNotEmpty && role == 'client') {
       // TODO: Gérer la redirection pour les liens client directs si nécessaire
        // Pour l'instant, on peut rediriger vers la page d'accueil ou afficher une erreur.
       print('DEBUG ConversationRedirectScreen: Lien client direct détecté, non géré pour l\'instant.');
       context.go('/'); // Rediriger vers la page d'accueil
    }
    else {
      // Si les paramètres sont manquants ou le rôle n'est pas reconnu, rediriger vers la page d'accueil
      print('DEBUG ConversationRedirectScreen: Paramètres insuffisants ou rôle inconnu. Redirection vers /.');
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un simple indicateur de chargement pendant la redirection
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 