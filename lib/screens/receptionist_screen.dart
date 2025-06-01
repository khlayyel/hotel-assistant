import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';
import '../config/platform_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final sender    = (data['senderName'] ?? "").toString();
    final text      = data['text'] ?? "";
    final isMe      = sender == widget.receptionistName;
    final isBot     = sender == "Bot";
    final alignRight= isMe || isBot;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!alignRight) ...[
            CircleAvatar(
              backgroundColor: Colors.grey[700],
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    color: alignRight ? Colors.white : Color(0xFFe2001a),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    shadows: alignRight ? [Shadow(color: Colors.black26, blurRadius: 2)] : null,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(14),
                  margin: EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: alignRight ? Color(0xFF2d2b31) : Colors.grey[850],
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
          if (alignRight) ...[
            SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: isMe ? Colors.grey[900] : Colors.grey[700],
              child: Icon(
                isMe ? Icons.headset_mic : Icons.smart_toy,
                color: Color(0xFFe2001a),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(color: Color(0xFFe2001a), width: 1.5), // Rouge Hotix
            ),
            child: Row(
              children: [
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Écrivez votre message...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFFe2001a)), // Rouge Hotix
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Conversation avec le client", style: TextStyle(color: Color(0xFF232323), fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF0d1a36),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Nettoyer les données de session
              SharedPreferences.getInstance().then((prefs) {
                prefs.remove('clientNom');
                prefs.remove('clientPrenom');
                prefs.remove('clientHotelId');
                prefs.remove('clientHotelName');
              });
              // Rediriger vers la page de connexion
              PlatformConfig.navigateToUrl(Environment.webAppUrl, context);
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0d1a36), Color(0xFF1976d2)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 400 : 600),
            child: Column(
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
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Color(0xFF0d1a36), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: "Écrivez votre message...",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                          ),
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                          onSubmitted: (value) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Color(0xFF0d1a36)),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildEscalationBadge(),
              ],
            ),
          ),
        ),
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

// Remplacer la fonction navigateToUrl par :
void navigateToUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Impossible d\'ouvrir $url';
  }
} 