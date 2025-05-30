import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotix_assistant/screens/receptionist_auth_screen.dart';

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