import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:html' as html;
import '../config/environment.dart';

class ReceptionistScreen extends StatefulWidget {
  final String conversationId;
  final String receptionistName;
  final String? assignedReceptionistName;

  const ReceptionistScreen({
    Key? key,
    required this.conversationId,
    required this.receptionistName,
    this.assignedReceptionistName,
  }) : super(key: key);

  @override
  State<ReceptionistScreen> createState() => _ReceptionistScreenState();
}

class _ReceptionistScreenState extends State<ReceptionistScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Stream<QuerySnapshot>? _messagesStream;
  bool _isTyping = false;
  bool _isConversationEscalated = false;

  @override
  void initState() {
    super.initState();
    _listenToMessages();
    _checkEscalationStatus();
  }

  void _listenToMessages() {
    _messagesStream = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Future<void> _checkEscalationStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();
    if (doc.exists) {
      setState(() {
        _isConversationEscalated = doc.data()?['isEscalated'] == true;
      });
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    String userMessage = _controller.text.trim();
    _controller.clear();

    // Vérifier si la conversation est déjà prise en charge
    final conversationDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();

    if (conversationDoc.exists && 
        conversationDoc.data()?['assignedReceptionist'] != null && 
        conversationDoc.data()?['assignedReceptionist']['name'] != widget.receptionistName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cette conversation est déjà prise en charge par un autre réceptionniste.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Assigner le réceptionniste à la conversation
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
          'isEscalated': true,
          'assignedReceptionist': {'name': widget.receptionistName},
        });

    // Envoyer le message
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .add({
          'text': userMessage,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
          'senderName': widget.receptionistName,
        });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessage(Map<String, dynamic> data) {
    // On considère que le réceptionniste courant est l'utilisateur de cette page
    bool isReceptionistMessage = data['senderName'] == widget.receptionistName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: isReceptionistMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isReceptionistMessage)
            CircleAvatar(
              backgroundColor: Colors.grey[700],
              child: Icon(Icons.person, color: Colors.white), // Client
            ),
          if (!isReceptionistMessage) SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isReceptionistMessage ? Colors.blueAccent : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['senderName'] ?? "",
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(data['text'], style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
          if (isReceptionistMessage) SizedBox(width: 10),
          if (isReceptionistMessage)
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.headset_mic, color: Colors.white), // Réceptionniste
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: "Écrivez votre message...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                ),
                style: TextStyle(color: Colors.white),
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationBadge() {
    if (_isConversationEscalated) {
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Conversation en cours',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conversation avec le client"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => html.window.location.href = Environment.webAppUrl,
            tooltip: 'Retour à l\'accueil',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return ListView(
                    controller: _scrollController,
                    children: [],
                  );
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildMessage(data);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
          SizedBox(height: 20),
          _buildEscalationBadge(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    // Libérer le réceptionniste quand il quitte la conversation
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
          'assignedReceptionist': null,
          'isEscalated': false
        });
  }
} 