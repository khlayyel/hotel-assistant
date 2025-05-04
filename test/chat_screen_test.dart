import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_assistant/main.dart';

void main() {
  testWidgets('ChatScreen UI Test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(HotelChatbotApp());

    // Verify that the initial state is correct
    expect(find.text('Hotel Chatbot Assistant'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);

    // Test sending a message
    await tester.enterText(find.byType(TextField), 'Bonjour');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify that the message was sent
    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.text('Assistant is typing...'), findsOneWidget);

    // Wait for the response
    await tester.pumpAndSettle();

    // Verify that we got a response
    expect(find.text('Assistant is typing...'), findsNothing);
    expect(find.byType(ChatMessage), findsNWidgets(2)); // User message and bot response
  });
} 