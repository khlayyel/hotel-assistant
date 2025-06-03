// ==========================
// chat_screen_test.dart : Test widget du chat pour vérifier l'UI et le comportement de base
// ==========================

// Importation de la librairie Flutter pour les widgets
import 'package:flutter/material.dart';
// Importation de la librairie de test Flutter
import 'package:flutter_test/flutter_test.dart';
// Importation du point d'entrée principal de l'application
import 'package:hotel_assistant/main.dart';

// Fonction principale de test
void main() {
  // Test widget pour vérifier l'UI et le comportement de base du ChatScreen
  testWidgets('ChatScreen UI Test', (WidgetTester tester) async {
    // Construit l'application et déclenche un frame
    await tester.pumpWidget(HotelChatbotApp());

    // Vérifie que l'état initial est correct
    expect(find.text('Hotel Chatbot Assistant'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);

    // Teste l'envoi d'un message
    await tester.enterText(find.byType(TextField), 'Bonjour');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Vérifie que le message a été envoyé
    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.text('Assistant is typing...'), findsOneWidget);

    // Attend la réponse
    await tester.pumpAndSettle();

    // Vérifie que la réponse a été reçue
    expect(find.text('Assistant is typing...'), findsNothing);
    expect(find.byType(ChatMessage), findsNWidgets(2)); // Message utilisateur et réponse bot
  });
} 