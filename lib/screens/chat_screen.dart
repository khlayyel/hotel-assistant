import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotix_assistant/screens/receptionist_auth_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hotix_assistant/config/environment.dart';

class ChatScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ... (existing code)

  void _copyAccessLink() {
    final link = 'https://hotix-assistant.web.app/chat?conversationId=$_conversationId&receptionistName=${Uri.encodeComponent(_receptionistName)}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lien copié dans le presse-papiers')),
    );
  }

  void _handleAccessLink(String link) {
    try {
      final uri = Uri.parse(link);
      final conversationId = uri.queryParameters['conversationId'];
      final receptionistName = uri.queryParameters['receptionistName'];
      final hotelId = uri.queryParameters['hotelId'];

      if (conversationId != null && conversationId.isNotEmpty && receptionistName != null && receptionistName.isNotEmpty && hotelId != null && hotelId.isNotEmpty) {
        final loginUrl = '/receptionniste/login?conversationId=' + Uri.encodeComponent(conversationId) +
                         '&receptionistName=' + Uri.encodeComponent(receptionistName) +
                         '&hotelId=' + Uri.encodeComponent(hotelId);
        print('DEBUG ChatScreen._handleAccessLink: Navigation vers $loginUrl');
        context.go(loginUrl);
      } else {
         print('DEBUG ChatScreen._handleAccessLink: Paramètres manquants dans le lien d\'accès. conversationId: $conversationId, receptionistName: $receptionistName, hotelId: $hotelId');
      }

    } catch (e) {
      print('Erreur lors du traitement du lien d\'accès: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du traitement du lien.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le redirector de go_router dans main.dart gère l'URL initiale.
    // Cette logique de vérification d'URL et de retour direct de ReceptionnistAuthScreen n'est plus nécessaire ici.
    /*
    if (Uri.base.queryParameters['role'] == 'receptionist') {
      final conversationId = Uri.base.pathSegments.length >= 2 && Uri.base.pathSegments[0] == 'conversation'
          ? Uri.base.pathSegments[1]
          : null;
      final receptionistName = Uri.base.queryParameters['receptionistName'];
      if (conversationId != null && receptionistName != null && receptionistName.isNotEmpty) {
        return ReceptionistAuthScreen(
          conversationId: conversationId,
          receptionistName: receptionistName,
        );
      }
    }
    */
    // ... (existing code)
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          ElevatedButton(
            // Utiliser context.go() pour la navigation interne (retour à la page d'accueil)
            onPressed: () => context.go('/'), // Naviguer vers la route par défaut (accueil)
            child: Text('Retour'),
          ),
        ],
      ),
    );
  }
} 