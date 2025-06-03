// ==========================
// chat_screen.dart : Écran de chat principal pour le client
// ==========================

// Importation de la librairie Flutter pour l'UI
import 'package:flutter/material.dart'; // Permet de créer des widgets visuels
// Importation pour la gestion du presse-papiers (copier/coller)
import 'package:flutter/services.dart';
// Importation de l'écran d'authentification réceptionniste
import 'package:hotix_assistant/screens/receptionist_auth_screen.dart';

// Widget principal pour l'écran de chat du client
class ChatScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

// Classe d'état associée à ChatScreen
class _ChatScreenState extends State<ChatScreen> {
  // ... (existing code)

  // Méthode pour copier le lien d'accès à la conversation dans le presse-papiers
  void _copyAccessLink() {
    final link = 'https://hotix-assistant.web.app/chat?conversationId=$_conversationId&receptionistName=${Uri.encodeComponent(_receptionistName)}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lien copié dans le presse-papiers')),
    );
  }

  // Méthode pour traiter un lien d'accès et naviguer vers l'écran d'authentification réceptionniste
  void _handleAccessLink(String link) {
    try {
      final uri = Uri.parse(link);
      final conversationId = uri.queryParameters['conversationId'];
      final receptionistName = uri.queryParameters['receptionistName'];

      if (conversationId != null && receptionistName != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceptionistAuthScreen(
              conversationId: conversationId,
              receptionistName: Uri.decodeComponent(receptionistName),
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors du traitement du lien: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
  }
} 