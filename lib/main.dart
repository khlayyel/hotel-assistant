import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';  // Import the Firebase options file
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'screens/gestion_hotels_screen.dart'; // Nouvel import
import 'package:dropdown_search/dropdown_search.dart';
import 'config/environment.dart';

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Use the generated options
    );
    if (kIsWeb) {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      messaging.requestPermission().then((_) {
        messaging.getToken().then((token) {
          print("FCM Token: $token");
        }).catchError((e) {
          print("Error getting FCM token: $e");
        });
      });
    }    runApp(HotelChatbotApp());
  }


class HotelChatbotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hotel Assistant Chatbot',
      theme: ThemeData.dark(),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  String? _conversationId;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _showWelcomeMessage = true;
  bool _isTyping = false;
  bool _showGestionButton = false;
  List<String> userHistory = [];
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final ScrollController _scrollController = ScrollController();
  String email = "khalilouerghemmi@gmail.com";
  String? _clientNom;
  String? _clientPrenom;
  String? _selectedHotelId;
  String? _selectedHotelName;
  final TextEditingController _hotelSearchController = TextEditingController();
  List<Map<String, dynamic>> _hotelSuggestions = [];
  bool _showHotelSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadClientInfo();
    _hotelSearchController.addListener(_onHotelInputChanged);
  }

  void _onHotelInputChanged() async {
    final input = _hotelSearchController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _hotelSuggestions = [];
        _showHotelSuggestions = false;
      });
      return;
    }
    final querySnapshot = await FirebaseFirestore.instance
        .collection('hotels')
        .orderBy('name')
        .startAt([input])
        .endAt([input + '\uf8ff'])
        .limit(10)
        .get();
    setState(() {
      _hotelSuggestions = querySnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name']})
          .toList();
      _showHotelSuggestions = true;
    });
  }

  Future<void> _loadClientInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clientNom = prefs.getString('clientNom');
      _clientPrenom = prefs.getString('clientPrenom');
      _selectedHotelId = prefs.getString('clientHotelId');
      _selectedHotelName = prefs.getString('clientHotelName');
    });
    
    // Vérifier si les informations sont valides
    if (_clientNom == null || _clientNom!.isEmpty || 
        _clientPrenom == null || _clientPrenom!.isEmpty || 
        _selectedHotelId == null || _selectedHotelId!.isEmpty) {
      // Réinitialiser les préférences si elles sont invalides
      await prefs.remove('clientNom');
      await prefs.remove('clientPrenom');
      await prefs.remove('clientHotelId');
      await prefs.remove('clientHotelName');
      
      // Afficher le dialogue de bienvenue
      WidgetsBinding.instance.addPostFrameCallback((_) => _showClientInfoDialog());
    }
  }

  Future<void> _resetClientInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('clientNom');
    await prefs.remove('clientPrenom');
    await prefs.remove('clientHotelId');
    await prefs.remove('clientHotelName');
    
    setState(() {
      _clientNom = null;
      _clientPrenom = null;
      _selectedHotelId = null;
      _selectedHotelName = null;
    });
    
    _showClientInfoDialog();
  }

  Future<void> _showClientInfoDialog() async {
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final hotelSearchController = TextEditingController();
    List<Map<String, dynamic>> allHotels = [];
    List<Map<String, dynamic>> filteredHotels = [];
    String? selectedHotelId;
    String? selectedHotelName;
    bool isLoadingHotels = true;
    bool showDropdown = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> loadHotels() async {
            final querySnapshot = await FirebaseFirestore.instance
                .collection('hotels')
                .orderBy('name')
                .get();
            allHotels = querySnapshot.docs
                .map((doc) => {'id': doc.id, 'name': doc['name']})
                .toList();
            filteredHotels = List.from(allHotels);
            isLoadingHotels = false;
            setStateDialog(() {});
          }
          if (isLoadingHotels) {
            loadHotels();
          }
          return AlertDialog(
            title: Text('Bienvenue !'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Veuillez choisir l'hôtel concerné. Cela nous permettra, en cas de besoin, de vous mettre en relation avec un réceptionniste de l'établissement exact que vous avez sélectionné.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: nomController,
                    decoration: InputDecoration(labelText: 'Nom'),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: prenomController,
                    decoration: InputDecoration(labelText: 'Prénom'),
                  ),
                  SizedBox(height: 12),
                  isLoadingHotels
                    ? Center(child: CircularProgressIndicator())
                    : allHotels.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Aucun hôtel disponible', style: TextStyle(color: Colors.red)),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: hotelSearchController,
                                decoration: InputDecoration(
                                  labelText: "Rechercher un hôtel",
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setStateDialog(() {
                                    filteredHotels = allHotels
                                        .where((h) => h['name']
                                            .toLowerCase()
                                            .contains(value.toLowerCase()))
                                        .toList();
                                    if (selectedHotelName != null &&
                                        !filteredHotels.any((h) => h['name'] == selectedHotelName)) {
                                      selectedHotelName = null;
                                      selectedHotelId = null;
                                    }
                                  });
                                },
                              ),
                              SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: selectedHotelName != null && filteredHotels.any((h) => h['name'] == selectedHotelName)
                                    ? selectedHotelName
                                    : null,
                                items: filteredHotels
                                    .map((hotel) => DropdownMenuItem<String>(
                                          value: hotel['name'],
                                          child: Text(hotel['name']),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  final hotel = allHotels.firstWhere((h) => h['name'] == value);
                                  setStateDialog(() {
                                    selectedHotelId = hotel['id'];
                                    selectedHotelName = hotel['name'];
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: "Sélectionner un hôtel",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (nomController.text.trim().isEmpty || prenomController.text.trim().isEmpty || selectedHotelId == null) return;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('clientNom', nomController.text.trim());
                  await prefs.setString('clientPrenom', prenomController.text.trim());
                  await prefs.setString('clientHotelId', selectedHotelId!);
                  await prefs.setString('clientHotelName', selectedHotelName ?? '');
                  setState(() {
                    _clientNom = nomController.text.trim();
                    _clientPrenom = prenomController.text.trim();
                    _selectedHotelId = selectedHotelId;
                    _selectedHotelName = selectedHotelName;
                  });
                  Navigator.pop(context);
                },
                child: Text('Valider'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Création d'une conversation dans Firestore
  Future<void> _createConversation() async {
    final docRef = await FirebaseFirestore.instance.collection('conversations').add({
      'createdAt': FieldValue.serverTimestamp(),
      'isEscalated': false,
      'isLocked': false,
      'waitingForReceptionist': false,
      'lastUpdated': FieldValue.serverTimestamp(),
      'clientNom': _clientNom,
      'clientPrenom': _clientPrenom,
      'clientHotelId': _selectedHotelId,
      'clientHotelName': _selectedHotelName,
      'receptionnisteNom': null,
    });
    setState(() {
      _conversationId = docRef.id;
    });
    print('Conversation créée avec ID: $_conversationId');
  }

  Future<bool> _isFallbackResponse(String response) async {
    try {
      // Charger le fichier JSON
      final String jsonString = await rootBundle.loadString('lib/data/fallback_responses.json');
      final Map<String, dynamic> fallbackData = json.decode(jsonString);
      final lowercaseResponse = response.toLowerCase();
      
      // Parcourir toutes les langues
      for (var language in fallbackData['fallback_responses'].keys) {
        var languageData = fallbackData['fallback_responses'][language];
        
        // Parcourir toutes les catégories pour chaque langue
        for (var category in languageData.keys) {
          var phrases = languageData[category] as List<dynamic>;
          
          // Vérifier chaque phrase dans la catégorie
          for (var phrase in phrases) {
            if (lowercaseResponse.contains(phrase.toLowerCase())) {
              return true;
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Erreur lors de la vérification de la réponse: $e');
      return false;
    }
  }

  Future<bool> _hotelExiste(String? hotelId) async {
    if (hotelId == null) return false;
    final doc = await FirebaseFirestore.instance.collection('hotels').doc(hotelId).get();
    return doc.exists && doc.data() != null && doc.data()!.isNotEmpty;
  }

  Future<bool> _donneeHotelExiste(String champ) async {
    if (_selectedHotelId == null) return false;
    final doc = await FirebaseFirestore.instance.collection('hotels').doc(_selectedHotelId).get();
    if (!doc.exists) return false;
    final data = doc.data();
    return data != null && data[champ] != null && data[champ].toString().isNotEmpty;
  }

  bool _questionConcerneHotel(String message) {
    final lower = message.toLowerCase();
    // Détection stricte de tous les sujets métier sensibles
    return lower.contains('hôtel') || lower.contains('hotel') || lower.contains('prix') || lower.contains('tarif') || lower.contains('chambre') || lower.contains('service') || lower.contains('horaire') || lower.contains('réservation') || lower.contains('disponibilité') || lower.contains('spa') || lower.contains('restaurant') || lower.contains('petit déjeuner') || lower.contains('check-in') || lower.contains('check out') || lower.contains('arrivée') || lower.contains('départ');
  }

  void _logChat() {
    print('--- Chat actuel ---');
    for (var msg in _messages) {
      print('[36m${msg.isUser ? 'Client' : 'Bot'} : ${msg.text}[0m');
    }
    print('-------------------');
  }

  // Fonction naïve de détection de langue (à améliorer si besoin)
  String detectLanguage(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'^[a-zA-Z\s\?\!]+\b(hello|hi|how|please|thanks|you)\b').hasMatch(lower)) return 'en';
    if (lower.contains('¿') || lower.contains('¡') || lower.contains('cómo') || lower.contains('gracias') || lower.contains('buenos')) return 'es';
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) return 'ar';
    return 'fr';
  }

  void _sendMessage() async {
    // Créer la conversation si nécessaire
    if (_conversationId == null) {
      await _createConversation();
    }
    if (_controller.text.isEmpty) return;

    String userMessage = _controller.text.trim();
    _controller.clear();
    print('Message utilisateur : $userMessage');

    // Détection de la langue du message utilisateur
    String userLang = detectLanguage(userMessage);
    String systemPrompt;
    if (userLang == 'en') {
      systemPrompt = "You are the virtual assistant of the hotel "+(_selectedHotelName ?? "")+". Answer naturally, warmly and professionally, like a real receptionist. Always be polite, help the client with their needs (reservations, services, info, etc.), and never ask for sensitive information. The client is speaking in English.";
    } else if (userLang == 'es') {
      systemPrompt = "Eres el asistente virtual del hotel "+(_selectedHotelName ?? "")+". Responde de manera natural, cálida y profesional, como un verdadero recepcionista. Sé siempre educado, ayuda al cliente con sus necesidades (reservas, servicios, información, etc.) y nunca pidas información sensible. El cliente está hablando en español.";
    } else if (userLang == 'ar') {
      systemPrompt = "أنت المساعد الافتراضي لفندق "+(_selectedHotelName ?? "")+". أجب بطريقة طبيعية ودافئة واحترافية، مثل موظف استقبال حقيقي. كن دائمًا مهذبًا وساعد العميل في احتياجاته (الحجوزات، الخدمات، المعلومات، إلخ)، ولا تطلب أبدًا معلومات حساسة. العميل يتحدث بالعربية.";
    } else {
      systemPrompt = "Tu es l'assistant virtuel de l'hôtel "+(_selectedHotelName ?? "")+". Réponds de façon naturelle, chaleureuse et professionnelle, comme un vrai réceptionniste. Sois toujours poli, aide le client pour ses besoins (réservations, services, infos, etc.), et ne demande jamais d'informations sensibles. Le client s'exprime dans sa langue.";
    }

    // Gestion spéciale pour le message "gestion"
    if (userMessage.toLowerCase() == "gestion") {
      setState(() {
        _showGestionButton = true;
        _messages.add(ChatMessage(text: userMessage, isUser: true));
        _messages.add(ChatMessage(
          text: "Bienvenue dans la gestion des hôtels ! Vous pouvez accéder à l'interface de gestion en cliquant sur le bouton ci-dessous.",
          isUser: false
        ));
      });
      _logChat();
      return;
    }

    if (_showWelcomeMessage) {
      setState(() {
        _showWelcomeMessage = false;
      });
    }

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isTyping = true;
      _messages.add(ChatMessage(text: "Bot is typing...", isUser: false, isTemporary: true));
    });
    _logChat();

    // Sauvegarder le message de l'utilisateur dans Firestore
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add({
        'text': userMessage,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur sauvegarde message: $e');
    }

    // LOGIQUE STRICTE : jamais de réponse IA sur un sujet métier, toujours escalade
    if (_questionConcerneHotel(userMessage)) {
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(
          text: "Je suis un assistant virtuel et je ne peux pas répondre à cette question spécifique. Voulez-vous qu'un réceptionniste humain vous aide ?",
          isUser: false,
          hasButtons: true,
        ));
      });
      print('Question métier détectée, proposition d\'escalade.');
      _logChat();
      return;
    }

    try {
      final prompt = systemPrompt + "\n" +
        _messages
          .where((msg) => !msg.isTemporary)
          .map((msg) => (msg.isUser ? "Client : " : "Assistant : ") + msg.text)
          .join("\n") +
        "\nAssistant :";
      print('Prompt envoyé à l\'IA : $prompt');
      // Appel à Ollama
      final predictionResponse = await http.post(
        Uri.parse(Environment.apiBaseUrl + '/predictions'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "input": {
            "prompt": prompt
          }
        }),
      );
      final predictionData = jsonDecode(predictionResponse.body);
      print('Réponse brute Groq : ' + predictionResponse.body);
      String botReply = '';
      if (predictionData['status'] == 'succeeded' && predictionData['output'] != null && predictionData['output'].isNotEmpty) {
        botReply = predictionData['output'][0];
      } else {
        botReply = 'Je suis désolé, je n\'ai pas pu générer de réponse. Veuillez réessayer.';
      }
      print('Réponse IA : $botReply');

      // Nouvelle logique fallback : n'affiche le fallback QUE si la réponse est vide ou très courte
      bool isFallback = botReply.trim().isEmpty || botReply.trim().length < 5;
      if (isFallback) {
        setState(() {
          _messages.removeWhere((msg) => msg.isTemporary);
          _messages.add(ChatMessage(
            text: "Je suis désolé, je n'ai pas la réponse exacte à votre question. Voulez-vous qu'un réceptionniste humain vous aide ?",
            isUser: false,
            hasButtons: true,
          ));
        });
        print('Fallback détecté, affichage des boutons Oui/Non');
        _logChat();
        return;
      } else {
        setState(() {
          _messages.removeWhere((msg) => msg.isTemporary);
          _messages.add(ChatMessage(text: botReply, isUser: false));
        });
        _logChat();
      }
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(text: "Je suis désolé, une erreur est survenue. Veuillez réessayer.", isUser: false));
      });
      print('❌ Erreur lors de la génération de la réponse: $e');
      _logChat();
    }

    setState(() {
      _isTyping = false;
    });
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  void _handleEscalationResponse(String response) async {
    setState(() {
      int idx = _messages.indexWhere((msg) => msg.hasButtons == true);
      if (idx != -1) {
        final oldMsg = _messages[idx];
        _messages[idx] = ChatMessage(
          text: oldMsg.text,
          isUser: oldMsg.isUser,
          hasButtons: false,
        );
      }
    });
    if (response == "Oui") {
      List<Map<String, String>> conversationContext = _buildChatContext();
      try {
        // Générer le résumé via Ollama
        final summaryPrompt = "Fais un résumé concis et clair de la conversation entre le client et le chatbot. Le résumé doit être dans la langue du client et aider le réceptionniste à comprendre rapidement le contexte et les besoins du client. Sois bref et précis.\n" +
          conversationContext.map((m) => (m["role"] == "user" ? "Client : " : "Assistant : ") + (m["content"] ?? "")).join("\n") +
          "\nAssistant :";
        
        final summaryResponse = await http.post(
          Uri.parse(Environment.apiBaseUrl + '/predictions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "input": {
              "prompt": summaryPrompt
            }
          }),
        );
        
        final summaryData = jsonDecode(summaryResponse.body);
        String summary = '';
        if (summaryData.containsKey('status') && summaryData['status'] == 'succeeded' && summaryData['output'] != null && summaryData['output'].isNotEmpty) {
          summary = summaryData['output'][0];
        } else {
          summary = 'Erreur : aucun résumé généré.\nDétail technique : ' + summaryData.toString();
        }

        // Vérifier si un réceptionniste est déjà assigné
        final conversationDoc = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(_conversationId)
            .get();

        if (conversationDoc.exists && conversationDoc.data()?['assignedReceptionist'] != null) {
          setState(() {
            _messages.add(ChatMessage(
              text: "Un réceptionniste est déjà en train de vous assister. Veuillez patienter...",
              isUser: false
            ));
          });
          return;
        }

        // Récupérer tous les réceptionnistes disponibles
        final receptionistsSnap = await FirebaseFirestore.instance
            .collection('hotels')
            .doc(_selectedHotelId)
            .collection('receptionists')
            .where('isAvailable', isEqualTo: true)
            .get();

        if (receptionistsSnap.docs.isEmpty) {
          setState(() {
            _messages.add(ChatMessage(
              text: "Désolé, aucun réceptionniste n'est disponible pour le moment. Veuillez réessayer dans quelques minutes.",
              isUser: false
            ));
          });
          return;
        }

        // Sélectionner le premier réceptionniste disponible
        final selectedReceptionist = receptionistsSnap.docs.first;
        final receptionistEmail = selectedReceptionist['email'] as String;
        final receptionistName = selectedReceptionist['name'] as String;

        // Générer un lien unique pour cette conversation
        final conversationLink = '${Environment.webAppUrl}/conversation/$_conversationId';

        // Mettre à jour le statut du réceptionniste
        await FirebaseFirestore.instance
            .collection('hotels')
            .doc(_selectedHotelId)
            .collection('receptionists')
            .doc(selectedReceptionist.id)
            .update({
              'isAvailable': false,
              'currentConversationId': _conversationId
            });

        // Mettre à jour la conversation
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(_conversationId)
            .update({
              'isEscalated': true,
              'assignedReceptionist': {
                'id': selectedReceptionist.id,
                'name': receptionistName,
                'email': receptionistEmail
              },
              'conversationLink': conversationLink
            });

        // Envoyer la notification au réceptionniste sélectionné
        final responseNotif = await http.post(
          Uri.parse(Environment.apiBaseUrl + '/sendNotification'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Nouvelle conversation client',
            'body': 'Un client a besoin de votre assistance !\n\nRésumé de la conversation :\n$summary',
            'conversationId': _conversationId,
            'emails': [receptionistEmail],
            'conversationLink': conversationLink
          }),
        );

        setState(() {
          _messages.add(ChatMessage(
            text: "Un réceptionniste a été notifié et va rejoindre la conversation...",
            isUser: false
          ));
          _messages.add(ChatMessage(
            text: "Résumé pour le réceptionniste :",
            isUser: false
          ));
          _messages.add(ChatMessage(
            text: summary,
            isUser: false
          ));
        });

        _logChat();
      } catch (e) {
        print('Erreur lors de l\'escalade : $e');
        setState(() {
          _messages.add(ChatMessage(
            text: "Une erreur s'est produite lors de la mise en relation avec un réceptionniste. Veuillez réessayer.",
            isUser: false
          ));
        });
      }
    } else {
      setState(() {
        _messages.add(ChatMessage(text: "D'accord, je vais essayer de mieux vous aider.", isUser: false));
      });
      _logChat();
    }
    _scrollToBottom();
  }

  String _buildResume() {
    if (userHistory.isEmpty) return "";
    
    // Compter les occurrences de chaque type d'action
    Map<String, int> actionCounts = {};
    for (String action in userHistory) {
      actionCounts[action] = (actionCounts[action] ?? 0) + 1;
    }
    
    // Construire un résumé plus détaillé
    String resume = "Résumé de la conversation :\n\n";
    resume += "Nombre total d'interactions : ${userHistory.length}\n\n";
    resume += "Détail des interactions :\n";
    
    actionCounts.forEach((action, count) {
      resume += "- $action (${count} fois)\n";
    });
    
    return resume;
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

  List<Map<String, String>> _buildChatContext() {
    List<Map<String, String>> context = [];
    // Toujours commencer par un prompt système professionnel
    context.add({
      "role": "system",
      "content": "Tu es un assistant virtuel pour un hôtel. Salue poliment le client et propose-lui de l'aider pour ses besoins liés à l'hôtel (réservations, services, informations, etc). Réponds toujours en français."
    });
    context.addAll(
      _messages
        .where((msg) => !msg.isTemporary)
        .map((msg) => {"role": msg.isUser ? "user" : "assistant", "content": msg.text})
        .toList()
    );
    return context;
  }

  Widget _buildEscalationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _handleEscalationResponse("Oui"),
          child: Text("Oui"),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blueAccent),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => _handleEscalationResponse("Non"),
          child: Text("Non"),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.redAccent),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(ChatMessage message, int index) {
    bool isUser = message.isUser;
    bool isTemporary = message.isTemporary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: Colors.grey[700],
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
          if (!isUser) SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blueAccent : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: isTemporary
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text("Bot is typing...", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              )
                  : message.hasButtons
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(message.text, style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        _buildEscalationButtons(),
                      ],
                    )
                  : Text(message.text, style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          if (isUser) SizedBox(width: 10),
          if (isUser)
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, color: Colors.white),
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
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                ),
                style: TextStyle(color: Colors.white),
                onSubmitted: (value) {
                  _sendMessage(); // Send the message when Enter is pressed
                },
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

  void _navigateToGestionHotels() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GestionHotelsScreen()),
    ).then((_) {
      // Après retour de l'écran de gestion
      setState(() {
        _showGestionButton = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcomeMessage && _messages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Hotel Chatbot Assistant"),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _resetClientInfo,
              tooltip: 'Réinitialiser les informations client',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Bonjour ! Je suis l'assistant virtuel de l'hôtel. Je peux répondre à vos questions générales sur l'établissement. Pour toute question sur les prix, chambres, services ou réservations, je vous proposerai d'être mis en relation avec un réceptionniste humain.",
                style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              _buildInputArea(),
              if (_showGestionButton)
                ElevatedButton(
                  onPressed: _navigateToGestionHotels,
                  child: Text("Gestion Hotels et Receptionnistes"),
                ),
              SizedBox(height: 20),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text("Hotel Chatbot Assistant"),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _resetClientInfo,
              tooltip: 'Réinitialiser les informations client',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: false,
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessage(_messages[index], index),
              ),
            ),
            _buildInputArea(),
            if (_showGestionButton)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _navigateToGestionHotels,
                  child: Text("Gestion Hotels et Receptionnistes"),
                ),
              ),
            SizedBox(height: 20),
          ],
        ),
      );
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isTemporary;
  final bool hasButtons; // Add this property to track if the message has buttons

  ChatMessage({required this.text, required this.isUser, this.isTemporary = false, this.hasButtons = false});
}
