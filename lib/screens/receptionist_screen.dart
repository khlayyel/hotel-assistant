import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';
import '../config/platform_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class ReceptionistScreen extends StatefulWidget {
  const ReceptionistScreen({Key? key}) : super(key: key);

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

  String? _conversationId;
  String? _receptionistName;
  String? _hotelId;

  @override
  void initState() {
    super.initState();
    final goRouterState = GoRouterState.of(context);
    _conversationId = goRouterState.pathParameters['conversationId'];
    _receptionistName = goRouterState.uri.queryParameters['receptionistName'];
    _hotelId = goRouterState.uri.queryParameters['hotelId'];

    print('DEBUG ReceptionistScreen: initState appelé. conversationId: $_conversationId, receptionistName: $_receptionistName, hotelId: $_hotelId');

    if (_conversationId != null && _conversationId!.isNotEmpty && _receptionistName != null && _receptionistName!.isNotEmpty && _hotelId != null && _hotelId!.isNotEmpty) {
       _listenToMessages();
      _checkEscalationStatus();
    } else {
       print('DEBUG ReceptionistScreen: Paramètres manquants dans l\'URL. Redirection vers /.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
         context.go('/');
      });
    }
  }

  void _listenToMessages() {
    if (_conversationId == null) return;
    _messagesStream = FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId!)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Future<void> _checkEscalationStatus() async {
     if (_conversationId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId!)
        .get();
    if (doc.exists) {
      setState(() {
        _isConversationEscalated = doc.data()?['isEscalated'] == true;
      });
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
     if (_conversationId == null || _receptionistName == null) {
        print('DEBUG ReceptionistScreen: Cannot send message, conversationId or receptionistName is null.');
        return;
    }
    String userMessage = _controller.text.trim();
    _controller.clear();

    final conversationDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId!)
        .get();

    if (conversationDoc.exists &&
        conversationDoc.data()?['assignedReceptionist'] != null &&
        conversationDoc.data()?['assignedReceptionist']['name'] != _receptionistName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cette conversation est déjà prise en charge par un autre réceptionniste (${conversationDoc.data()?['assignedReceptionist']['name']}).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (conversationDoc.exists && conversationDoc.data()?['assignedReceptionist'] == null) {
         await FirebaseFirestore.instance
            .collection('conversations')
            .doc(_conversationId!)
            .update({
              'isEscalated': true,
              'assignedReceptionist': {'name': _receptionistName},
            });
         print('DEBUG ReceptionistScreen: Assignation du réceptionniste ($_receptionistName) à la conversation ($_conversationId) lors du premier message.');
    }

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId!)
        .collection('messages')
        .add({
          'text': userMessage,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
          'senderName': _receptionistName,
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
    final isMe      = sender == _receptionistName;
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
                    color: Color(0xFFe2001a),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
     if (_conversationId == null || _receptionistName == null) return SizedBox.shrink();

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
              border: Border.all(color: Color(0xFFe2001a), width: 1.5),
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
                  icon: Icon(Icons.send, color: Color(0xFFe2001a)),
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
    if (_conversationId == null || _conversationId!.isEmpty || _receptionistName == null || _receptionistName!.isEmpty || _hotelId == null || _hotelId!.isEmpty) {
       return Scaffold(
        appBar: AppBar(title: Text("Chargement...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Conversation avec le client"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              context.go('/');
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              _buildEscalationBadge(),
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
              _buildInputArea(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (_conversationId != null && _receptionistName != null && _hotelId != null) {
       print('DEBUG ReceptionistScreen: Disposing. Attempting to free receptionist ($_receptionistName) from conversation ($_conversationId) at hotel ($_hotelId).');
       FirebaseFirestore.instance.collection('hotels').doc(_hotelId!).collection('receptionists').where('name', isEqualTo: _receptionistName!).get().then((snap) {
          if (snap.docs.isNotEmpty) {
            snap.docs.first.reference.update({'isAvailable': true, 'currentConversationId': null});
          }
        }).catchError((e) {
           print('ERREUR lors de la libération du réceptionniste dans dispose: $e');
        });

       FirebaseFirestore.instance
            .collection('conversations')
            .doc(_conversationId!)
            .update({
              'assignedReceptionist': null,
              'isEscalated': false
            }).catchError((e) {
               print('ERREUR lors de la mise à jour de la conversation dans dispose: $e');
            });

    } else {
       print('DEBUG ReceptionistScreen: Disposing, but conversationId, receptionistName, or hotelId is null. Cannot free receptionist.');
    }
  }

  void _onUserTypingStart() async {
     if (_conversationId == null || _receptionistName == null) return;

    String senderName = _receptionistName!;
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId!)
        .collection('messages')
        .where('isTyping', isEqualTo: true)
        .where('senderName', isEqualTo: senderName)
        .get();
    if (snap.docs.isEmpty) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId!)
          .collection('messages')
          .add({
        'isTyping': true,
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': senderName,
      });
    }
  }

  void _onUserTypingStop() async {
     if (_conversationId == null || _receptionistName == null) return;

    String senderName = _receptionistName!;
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId!)
        .collection('messages')
        .where('isTyping', isEqualTo: true)
        .where('senderName', isEqualTo: senderName)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isTemporary;
  final bool hasButtons;
  final String? senderName;
  final bool isTyping;

  ChatMessage({required this.text, required this.isUser, this.isTemporary = false, this.hasButtons = false, this.senderName, this.isTyping = false});
}

Future<void> libererReceptionniste(String hotelId, String receptionistId) async {
  await FirebaseFirestore.instance
      .collection('hotels')
      .doc(hotelId)
      .collection('receptionists')
      .doc(receptionistId)
      .update({
        'isAvailable': true,
        'currentConversationId': null,
      });
}

class AnimatedDots extends StatefulWidget {
  final String sender;
  AnimatedDots({required this.sender});
  @override
  _AnimatedDotsState createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
    _dotCount = StepTween(begin: 1, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) {
        String dots = '.' * _dotCount.value;
        return Text('${widget.sender} est en train d\'écrire$dots', style: TextStyle(color: Colors.white, fontSize: 16));
      },
    );
  }
}

void navigateToUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Impossible d\'ouvrir $url';
  }
} 