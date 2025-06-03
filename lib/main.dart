import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'screens/gestion_hotels_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'config/environment.dart';
import 'screens/receptionist_screen.dart';
import 'screens/choose_role_screen.dart';
import 'config/platform_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/receptionist_auth_screen.dart';

// ==========================
// main.dart : Point d'entrée principal de l'application Flutter
// Gère l'initialisation Firebase, le thème, la navigation et la logique du chatbot
// ==========================

// Importation des librairies nécessaires pour le fonctionnement de l'application
import 'dart:convert'; // Pour la manipulation des données JSON
import 'package:flutter/foundation.dart'; // Pour détecter la plateforme (web/mobile)
import 'package:flutter/material.dart'; // Pour la création de l'interface utilisateur Flutter
import 'package:http/http.dart' as http; // Pour effectuer des requêtes HTTP
import 'package:firebase_core/firebase_core.dart'; // Pour initialiser Firebase
import 'package:shared_preferences/shared_preferences.dart'; // Pour stocker des données localement (préférences)
import 'firebase_options.dart'; // Fichier de configuration Firebase généré automatiquement
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour accéder à la base de données Firestore
import 'package:firebase_messaging/firebase_messaging.dart'; // Pour la gestion des notifications push
import 'package:flutter/services.dart' show rootBundle; // Pour charger des fichiers locaux (ex: JSON)
import 'screens/gestion_hotels_screen.dart'; // Écran de gestion des hôtels (admin)
import 'package:dropdown_search/dropdown_search.dart'; // Widget pour les listes déroulantes avancées
import 'config/environment.dart'; // Fichier de configuration globale
import 'screens/receptionist_screen.dart'; // Écran de chat pour le réceptionniste
import 'screens/choose_role_screen.dart'; // Écran de choix du rôle (client/admin)
import 'config/platform_config.dart'; // Gestion navigation selon la plateforme
import 'package:url_launcher/url_launcher.dart'; // Pour ouvrir des liens externes
import 'screens/receptionist_auth_screen.dart'; // Écran d'authentification réceptionniste

// Fonction principale qui démarre l'application Flutter
void main() async {
  // S'assure que le binding Flutter est initialisé avant d'utiliser des plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase (nécessaire pour Firestore, Auth, etc.)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Utilise la config adaptée à la plateforme
    );
  } catch (e) {
    print('Firebase déjà initialisé: $e'); // Si déjà initialisé, on ignore l'erreur
  }

  // Si on est sur le web, on demande la permission pour les notifications push
  if (kIsWeb) {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    messaging.requestPermission().then((_) {
      messaging.getToken().then((token) {
        print("FCM Token: $token"); // Affiche le token de notification push
      }).catchError((e) {
        print("Error getting FCM token: $e");
      });
    });
  }
  
  // Lance l'application principale
  runApp(HotelChatbotApp());
}

// Classe qui définit le thème graphique de l'application (couleurs, polices, etc.)
class HotixTheme {
  // Définition des couleurs principales utilisées dans l'app
  static const Color hotixBlueDark = Color(0xFF0d1a36); // Bleu foncé
  static const Color hotixBlue = Color(0xFF1a237e); // Bleu intermédiaire
  static const Color hotixBlueLight = Color(0xFF1976d2); // Bleu clair
  static const Color hotixWhite = Color(0xFFF8F8F8);
  static const Color hotixGrey = Color(0xFF232323);

  // Méthode qui retourne le thème complet à appliquer à l'application
  static ThemeData get themeData => ThemeData(
    fontFamily: 'Roboto', // Police principale
    primaryColor: hotixBlueDark, // Couleur principale
    scaffoldBackgroundColor: hotixWhite, // Couleur de fond
    appBarTheme: AppBarTheme(
      backgroundColor: hotixBlueDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: hotixBlue, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: Colors.grey[700]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: hotixBlue, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: hotixBlue, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: hotixBlueDark, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: hotixBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: hotixBlue,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: hotixBlue,
      unselectedLabelColor: Colors.grey[700],
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: hotixBlue, width: 4),
      ),
    ),
  );
}

// Widget principal de l'application
class HotelChatbotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Détermine l'écran de démarrage selon la plateforme et l'URL (utile pour le web)
    Widget initialScreen = ChooseRoleScreen(); // Par défaut, choix du rôle
    if (kIsWeb) {
      final uri = Uri.base;
      final conversationIdFromUrl = uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'conversation'
          ? uri.pathSegments[1]
          : null;
      final role = uri.queryParameters['role'];
      String? receptionistName = uri.queryParameters['receptionistName'];
      if (role == 'receptionist' && conversationIdFromUrl != null && conversationIdFromUrl.isNotEmpty && receptionistName != null && receptionistName.isNotEmpty) {
        initialScreen = ReceptionistAuthScreen(
          conversationId: conversationIdFromUrl,
          receptionistName: receptionistName,
        );
      }
    }
    // Construction de l'application MaterialApp avec le thème défini
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Retire le bandeau "debug"
      title: 'Système de Chat Intelligent pour Hôtels', // Titre de l'app
      theme: HotixTheme.themeData, // Thème personnalisé
      home: initialScreen, // Premier écran affiché
      builder: (context, child) {
        // Ajoute un fond en dégradé à toute l'application
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [HotixTheme.hotixBlueDark, HotixTheme.hotixBlue],
            ),
          ),
          child: child,
        );
      },
    );
  }
}

// ==========================
// Définition du widget ChatScreen (écran principal du chat pour le client)
// ==========================

// Déclaration du widget ChatScreen qui gère l'affichage et la logique du chat principal
class ChatScreen extends StatefulWidget {
  // Constructeur du widget ChatScreen
  ChatScreen() {
    print('ChatScreen CONSTRUCTEUR appelé'); // Log pour le debug
  }
  @override
  State createState() => ChatScreenState(); // Retourne l'état associé
}

// Classe d'état associée à ChatScreen, gère toute la logique dynamique du chat
class ChatScreenState extends State<ChatScreen> {
  // Identifiant de la conversation en cours (Firestore)
  String? _conversationId;
  // Contrôleur pour le champ de saisie du message
  final TextEditingController _controller = TextEditingController();
  // FocusNode pour gérer le focus du champ de saisie
  final FocusNode _focusNode = FocusNode();
  // Liste des messages affichés dans le chat
  final List<ChatMessage> _messages = [];
  // Affiche ou non le message de bienvenue
  bool _showWelcomeMessage = true;
  // Indique si le bot est en train d'écrire
  bool _isTyping = false;
  // Affiche ou non le bouton de gestion (admin)
  bool _showGestionButton = false;
  // Historique des actions de l'utilisateur (pour résumé)
  List<String> userHistory = [];
  // Instance de FirebaseMessaging pour les notifications
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  // Contrôleur pour le scroll de la liste des messages
  final ScrollController _scrollController = ScrollController();
  // Email par défaut (à personnaliser si besoin)
  String email = "khalilouerghemmi@gmail.com";
  // Infos du client (nom, prénom, hôtel...)
  String? _clientNom;
  String? _clientPrenom;
  String? _selectedHotelId;
  String? _selectedHotelName;
  // Contrôleur pour la recherche d'hôtel
  final TextEditingController _hotelSearchController = TextEditingController();
  // Suggestions d'hôtels pour l'autocomplétion
  List<Map<String, dynamic>> _hotelSuggestions = [];
  // Affiche ou non les suggestions d'hôtel
  bool _showHotelSuggestions = false;
  // Indique si l'utilisateur est un réceptionniste
  bool _isReceptionist = false;
  // Indique si la conversation a été escaladée à un réceptionniste
  bool _isConversationEscalated = false;
  // Nom du réceptionniste assigné à la conversation
  String? _assignedReceptionistName;
  // Nom du réceptionniste (si mode réceptionniste)
  String? _receptionistName;
  // Flux de messages Firestore pour l'affichage en temps réel
  Stream<QuerySnapshot>? _messagesStream;
  // Résumé de la conversation (pour l'escalade)
  String? _resumeConversation;
  // Liste des noms de réceptionnistes de l'hôtel sélectionné
  List<String> _receptionistNames = [];

  // Méthode appelée à l'initialisation du widget
  @override
  void initState() {
    super.initState();

    // Si on est sur le web, on vérifie les paramètres d'URL pour la navigation directe
    if (kIsWeb) {
      final uri = Uri.base;
      final conversationIdFromUrl = uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'conversation'
          ? uri.pathSegments[1]
          : null;
      final role = uri.queryParameters['role'];
      String? receptionistName = uri.queryParameters['receptionistName'];
      
      // Si le rôle est réceptionniste, on redirige vers l'écran d'authentification réceptionniste
      if (role == 'receptionist') {
        if (receptionistName == null || receptionistName == 'null' || receptionistName.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorDialog("Le nom du réceptionniste doit être fourni dans l'URL (receptionistName).");
          });
          return;
        }
        if (conversationIdFromUrl != null && conversationIdFromUrl.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReceptionistAuthScreen(
                conversationId: conversationIdFromUrl,
                receptionistName: receptionistName,
              ),
            ),
          );
          return;
        }
      }
      
      // Si une conversation est spécifiée dans l'URL, on l'affiche directement
      if (conversationIdFromUrl != null && conversationIdFromUrl.isNotEmpty) {
        setState(() {
          _conversationId = conversationIdFromUrl;
          _showWelcomeMessage = false;
        });
        _listenToMessages(conversationIdFromUrl);
        _checkEscalationStatus(conversationIdFromUrl);
      }
    }

    // Ensuite, charger les infos client SEULEMENT si ce n'est PAS un réceptionniste
    if (!_isReceptionist) {
      _loadClientInfo();
      _hotelSearchController.addListener(_onHotelInputChanged);
    }
  }

  // Méthode pour charger les messages d'une conversation depuis Firestore
  Future<void> _loadConversationMessages(String conversationId) async {
    // Récupère les messages de la collection 'messages' de la conversation
    final messagesSnap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .get();
    setState(() {
      _messages.clear(); // Vide la liste actuelle
      for (var doc in messagesSnap.docs) {
        _messages.add(ChatMessage(
          text: doc['text'],
          isUser: doc['isUser'],
          senderName: doc.data().containsKey('senderName') ? doc['senderName'] : null,
        ));
      }
    });
  }

  // Méthode pour vérifier si la conversation a été escaladée à un réceptionniste
  Future<void> _checkEscalationStatus(String conversationId) async {
    // Récupère le document de la conversation
    final doc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _isConversationEscalated = data['isEscalated'] == true;
        _assignedReceptionistName = data['assignedReceptionist']?['name'];
      });
    }
  }

  // Méthode pour assigner un réceptionniste à une conversation
  Future<void> _assignReceptionistToConversation(String conversationId, String receptionistName) async {
    final doc = await FirebaseFirestore.instance.collection('conversations').doc(conversationId).get();
    if (doc.exists && (doc.data()?['assignedReceptionist'] == null)) {
      await FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
        'isEscalated': true,
        'assignedReceptionist': {'name': receptionistName},
      });
      // Met à jour la disponibilité du réceptionniste
      if (_selectedHotelId != null) {
        final receptionists = await FirebaseFirestore.instance.collection('hotels').doc(_selectedHotelId).collection('receptionists').where('name', isEqualTo: receptionistName).get();
        if (receptionists.docs.isNotEmpty) {
          await receptionists.docs.first.reference.update({'isAvailable': false, 'currentConversationId': conversationId});
        }
      }
      setState(() {
        _isConversationEscalated = true;
        _assignedReceptionistName = receptionistName;
      });
    } else if (doc.exists && doc.data()?['assignedReceptionist'] != null && doc.data()?['assignedReceptionist']['name'] != receptionistName) {
      // Si un autre réceptionniste est déjà en charge, affiche un message d'erreur
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Conversation déjà prise en charge'),
            content: Text('Cette conversation est déjà prise en charge par \\${doc.data()?['assignedReceptionist']['name']}.') ,
            actions: [
              ElevatedButton(
                onPressed: () => PlatformConfig.navigateToUrl(Environment.webAppUrl, context),
                child: Text('Retour'),
              ),
            ],
          ),
        );
      });
    }
  }

  // Méthode pour filtrer les suggestions d'hôtels lors de la saisie
  void _onHotelInputChanged() async {
    final input = _hotelSearchController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _hotelSuggestions = [];
        _showHotelSuggestions = false;
      });
      return;
    }
    // Recherche les hôtels dont le nom commence par la saisie utilisateur
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

  // Méthode pour charger les informations du client depuis les préférences locales
  Future<void> _loadClientInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clientNom = prefs.getString('clientNom');
      _clientPrenom = prefs.getString('clientPrenom');
      _selectedHotelId = prefs.getString('clientHotelId');
      _selectedHotelName = prefs.getString('clientHotelName');
    });
    // Vérifie que toutes les infos sont présentes, sinon réinitialise
    if (_clientNom == null || _clientNom!.isEmpty || 
        _clientPrenom == null || _clientPrenom!.isEmpty || 
        _selectedHotelId == null || _selectedHotelId!.isEmpty ||
        _selectedHotelName == null || _selectedHotelName!.isEmpty) {
      // Nettoie toutes les données de session
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
      // Affiche le dialogue de saisie client
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showClientInfoDialog();
      });
      return;
    }
    await _loadReceptionistNames();
  }

  // Méthode pour charger la liste des noms de réceptionnistes de l'hôtel sélectionné
  Future<void> _loadReceptionistNames() async {
    if (_selectedHotelId == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('hotels')
        .doc(_selectedHotelId)
        .collection('receptionists')
        .get();
    setState(() {
      _receptionistNames = snap.docs
          .map((doc) => (doc.data()['name'] as String?) ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    });
  }

  // Méthode pour réinitialiser les informations du client (déconnexion ou changement d'hôtel)
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

  // Méthode pour afficher le dialogue de saisie des informations client (nom, prénom, hôtel)
  Future<void> _showClientInfoDialog() async {
    print('_showClientInfoDialog appelé');
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
                    style: TextStyle(fontSize: 15, color: Colors.grey[700], fontStyle: FontStyle.italic),
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

  // Méthode pour créer une nouvelle conversation dans Firestore
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
    _listenToMessages(_conversationId!);
    print('Conversation créée avec ID: $_conversationId');
  }

  // Méthode pour vérifier si une réponse de l'IA est un fallback (réponse générique)
  Future<bool> _isFallbackResponse(String response) async {
    try {
      // Charge le fichier JSON des réponses de fallback
      final String jsonString = await rootBundle.loadString('lib/data/fallback_responses.json');
      final Map<String, dynamic> fallbackData = json.decode(jsonString);
      final lowercaseResponse = response.toLowerCase();
      // Parcourt toutes les langues et catégories pour détecter une phrase de fallback
      for (var language in fallbackData['fallback_responses'].keys) {
        var languageData = fallbackData['fallback_responses'][language];
        for (var category in languageData.keys) {
          var phrases = languageData[category] as List<dynamic>;
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

  // Méthode pour vérifier si un hôtel existe dans Firestore
  Future<bool> _hotelExiste(String? hotelId) async {
    if (hotelId == null) return false;
    final doc = await FirebaseFirestore.instance.collection('hotels').doc(hotelId).get();
    return doc.exists && doc.data() != null && doc.data()!.isNotEmpty;
  }

  // Méthode pour vérifier si une donnée spécifique existe pour l'hôtel sélectionné
  Future<bool> _donneeHotelExiste(String champ) async {
    if (_selectedHotelId == null) return false;
    final doc = await FirebaseFirestore.instance.collection('hotels').doc(_selectedHotelId).get();
    if (!doc.exists) return false;
    final data = doc.data();
    return data != null && data[champ] != null && data[champ].toString().isNotEmpty;
  }

  // Méthode pour détecter si une question concerne l'hôtel (métier)
  bool _questionConcerneHotel(String message) {
    final lower = message.toLowerCase();
    // Détection stricte de tous les sujets métier sensibles
    return lower.contains('hôtel') || lower.contains('hotel') || lower.contains('prix') || lower.contains('tarif') || lower.contains('chambre') || lower.contains('service') || lower.contains('horaire') || lower.contains('réservation') || lower.contains('disponibilité') || lower.contains('spa') || lower.contains('restaurant') || lower.contains('petit déjeuner') || lower.contains('check-in') || lower.contains('check out') || lower.contains('arrivée') || lower.contains('départ');
  }

  // Méthode pour afficher l'historique du chat dans la console (debug)
  void _logChat() {
    print('--- Chat actuel ---');
    for (var msg in _messages) {
      print('\x1b[36m${msg.isUser ? 'Client' : 'Bot'} : ${msg.text}\x1b[0m');
    }
    print('-------------------');
  }

  // Fonction naïve de détection de langue (fr, en, es, ar)
  String detectLanguage(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'^[a-zA-Z\s\?\!]+\b(hello|hi|how|please|thanks|you)\b').hasMatch(lower)) return 'en';
    if (lower.contains('¿') || lower.contains('¡') || lower.contains('cómo') || lower.contains('gracias') || lower.contains('buenos')) return 'es';
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) return 'ar';
    return 'fr';
  }

  // Méthode principale pour envoyer un message (client ou réceptionniste)
  void _sendMessage() async {
    // Si aucune conversation n'est en cours, on en crée une
    if (_conversationId == null) {
      await _createConversation();
    }
    // Si le champ de saisie est vide, on ne fait rien
    if (_controller.text.isEmpty) return;
    String userMessage = _controller.text.trim();
    _controller.clear();
    print('Message utilisateur : $userMessage');

    // Si un réceptionniste est déjà en charge, le bot ne répond plus (mode client)
    if (!_isReceptionist && _assignedReceptionistName != null) {
      // On enregistre juste le message du client, aucune logique bot
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add({
        'text': userMessage,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': (_clientPrenom != null && _clientNom != null) ? '$_clientPrenom $_clientNom' : 'Client',
      });
      setState(() {
        _messages.add(ChatMessage(
          text: userMessage,
          isUser: true,
          senderName: (_clientPrenom != null && _clientNom != null) ? '$_clientPrenom $_clientNom' : 'Client',
        ));
      });
      _scrollToBottom();
      return; // On arrête ici, le bot ne répond pas
    }

    // Envoi du message par le réceptionniste (mode réceptionniste)
    if (_isReceptionist) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add({
        'text': userMessage,
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': _receptionistName ?? 'Réceptionniste',
      });
      setState(() {
        _messages.add(ChatMessage(
          text: userMessage,
          isUser: true,
          senderName: _receptionistName ?? 'Réceptionniste',
        ));
      });
      _scrollToBottom();
      return;
    }

    // Envoi du message par le client (quand PAS de réceptionniste assigné)
    if (!_isReceptionist) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add({
        'text': userMessage,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': (_clientPrenom != null && _clientNom != null) ? '$_clientPrenom $_clientNom' : 'Client',
      });
    }

    await _removeBotTypingMessage();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true, senderName: (_clientPrenom != null && _clientNom != null) ? '$_clientPrenom $_clientNom' : 'Client'));
      _isTyping = true;
      _messages.add(ChatMessage(text: "Bot est en train d'écrire.", isUser: false, isTemporary: true));
    });
    _logChat();

    if (_isReceptionist) {
      _scrollToBottom();
      return;
    }

    // Nouvelle logique : n'escalader QUE si aucun réceptionniste n'est assigné ET pas déjà escaladé
    if (_questionConcerneHotel(userMessage) && _assignedReceptionistName == null && !_isConversationEscalated) {
      await _removeBotTypingMessage();
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add({
        'text': "Je suis un assistant virtuel et je ne peux pas répondre à cette question spécifique. Voulez-vous qu'un réceptionniste humain vous aide ?",
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': "Bot",
        'hasButtons': true,
      });
      print('Question métier détectée, proposition d\'escalade.');
      _logChat();
      return;
    }

    if (_showWelcomeMessage) {
      setState(() {
        _showWelcomeMessage = false;
      });
    }

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

    try {
      await _removeBotTypingMessage();
      final prompt = systemPrompt + "\n" +
        _messages
          .where((msg) => !msg.isTemporary)
          .map((msg) => (msg.isUser ? "Client : " : "Assistant : ") + msg.text)
          .join("\n") +
        "\nAssistant :";
      print('Prompt envoyé à l\'IA : $prompt');
      // Appel à l'API IA (GroqCloud via backend Node.js)
      final conversationDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .get();
      if (conversationDoc.exists && conversationDoc.data()?['assignedReceptionist'] != null) {
        // Un réceptionniste est en charge, le bot NE répond pas
        return;
      }
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

      try {
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(_conversationId)
            .collection('messages')
            .add({
          'text': botReply,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
          'senderName': "Bot",
        });
      } catch (e) {
        print('❌ Erreur sauvegarde message bot: $e');
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

  // Méthode pour gérer la réponse de l'utilisateur aux boutons d'escalade (Oui/Non)
  void _handleEscalationResponse(String response) async {
    // On retire les boutons de l'UI
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
        // Génère un résumé de la conversation via l'IA
        final summaryPrompt = """
Fais un résumé ultra-court (1 à 2 phrases maximum) de la demande ou du problème du client dans cette conversation, en français.
Ne répète pas les salutations ni les détails inutiles. Va à l'essentiel pour que le réceptionniste comprenne immédiatement le besoin du client.
Exemple attendu : \"Le client souhaite connaître les tarifs des chambres.\" ou \"Le client a un problème avec sa réservation.\"
Voici l'historique :
""" +
          conversationContext.map((m) => (m["role"] == "user" ? "Client : " : "Assistant : ") + (m["content"] ?? "")).join("\n") +
          "\nRésumé :";
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

        // Vérifie si un réceptionniste est déjà assigné
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

        // Récupère tous les réceptionnistes disponibles
        final receptionistsSnap = await FirebaseFirestore.instance
            .collection('hotels')
            .doc(_selectedHotelId)
            .collection('receptionists')
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

        // Envoie les notifications aux réceptionnistes
        for (var doc in receptionistsSnap.docs) {
          final emailsList = doc['emails'] as List<dynamic>;
          final receptionistName = doc['name'] as String?;
          if (receptionistName != null && receptionistName.isNotEmpty && emailsList.isNotEmpty) {
            final conversationLink = '${Environment.webAppUrl}/conversation/$_conversationId?role=receptionist&receptionistName=${Uri.encodeComponent(receptionistName)}';
            final List<String> emails = [];
            for (var emailObj in emailsList) {
              final email = emailObj['address'] as String?;
              if (email != null && email.isNotEmpty) {
                emails.add(email);
              }
            }
            if (emails.isNotEmpty) {
              await http.post(
                Uri.parse(Environment.apiBaseUrl + '/sendNotification'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'title': 'Nouvelle conversation client',
                  'body': 'Un client a besoin de votre assistance !\n\nRésumé de la conversation :\n$summary\n\nAccéder à la conversation : $conversationLink',
                  'conversationId': _conversationId,
                  'emails': emails,
                  'conversationLink': conversationLink
                }),
              );
            }
          }
        }

        // Ajoute les messages dans l'interface ET dans Firestore
        final messages = [
          {
            'text': "Patientez un moment, un réceptionniste va vous rejoindre immédiatement.",
            'isUser': false,
            'senderName': "Bot"
          },
          {
            'text': "Résumé pour le réceptionniste :",
            'isUser': false,
            'senderName': "Bot"
          },
          {
            'text': summary,
            'isUser': false,
            'senderName': "Bot"
          }
        ];
        setState(() {
          for (var msg in messages) {
            _messages.add(ChatMessage(
              text: msg['text'] as String,
              isUser: msg['isUser'] as bool,
              senderName: msg['senderName'] as String?,
            ));
          }
        });
        for (var msg in messages) {
          await FirebaseFirestore.instance
              .collection('conversations')
              .doc(_conversationId)
              .collection('messages')
              .add({
            ...msg,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
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
      await _removeBotTypingMessage();
      setState(() {
        _messages.add(ChatMessage(text: "D'accord, je vais essayer de mieux vous aider.", isUser: false));
      });
      _logChat();
    }
    _scrollToBottom();
    await _removeEscalationButtonsMessage();
  }

  // Méthode pour construire un résumé de la conversation (pour debug ou notification)
  String _buildResume() {
    if (userHistory.isEmpty) return "";
    // Compte les occurrences de chaque type d'action
    Map<String, int> actionCounts = {};
    for (String action in userHistory) {
      actionCounts[action] = (actionCounts[action] ?? 0) + 1;
    }
    // Construit un résumé détaillé
    String resume = "Résumé de la conversation :\n\n";
    resume += "Nombre total d'interactions : ${userHistory.length}\n\n";
    resume += "Détail des interactions :\n";
    actionCounts.forEach((action, count) {
      resume += "- $action (${count} fois)\n";
    });
    return resume;
  }

  // Méthode pour scroller automatiquement en bas de la liste des messages
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Méthode pour construire le contexte du chat pour l'IA (historique formaté)
  List<Map<String, String>> _buildChatContext() {
    List<Map<String, String>> context = [];
    // Ajoute un prompt système professionnel
    context.add({
      "role": "system",
      "content": "Tu es un assistant virtuel pour un hôtel. Salue poliment le client et propose-lui de l'aider pour ses besoins liés à l'hôtel (réservations, services, informations, etc). Réponds toujours en la meme langue du client."
    });
    context.addAll(
      _messages
        .where((msg) => !msg.isTemporary)
        .map((msg) => {"role": msg.isUser ? "user" : "assistant", "content": msg.text})
        .toList()
    );
    return context;
  }

  // Widget pour afficher les boutons d'escalade (Oui/Non)
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

  // Méthode build : construit l'interface utilisateur principale du chat
  @override
  Widget build(BuildContext context) {
    print('ChatScreen build appelé');
    final isMobile = MediaQuery.of(context).size.width < 700;
    // Si les infos client ne sont pas chargées, affiche un loader
    if (_clientNom == null || _clientPrenom == null || _selectedHotelId == null || _selectedHotelName == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Affichage principal du chat
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text("Chat Assistant"), backgroundColor: Color(0xFF0d1a36)),
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
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? 400 : 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Column(
                  children: [
                    _buildEscalationBadge(), // Affiche le badge si conversation escaladée
                    if (_messages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("👋", style: TextStyle(fontSize: 32)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Bonjour ${_clientPrenom ?? ''} ! Heureux de vous retrouver. Si vous avez la moindre question, n'hésitez pas à la poser ici, je suis là pour vous aider !",
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.55,
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
                              final message = ChatMessage(
                                text: data['text'] ?? "",
                                isUser: data['isUser'] ?? false,
                                senderName: data['senderName'],
                                hasButtons: data['hasButtons'] ?? false,
                              );
                              return _buildMessage(message, index);
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 12),
                    // Champ de saisie du message
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
                                hintStyle: TextStyle(color: Colors.grey[700]),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Méthode dispose : nettoyage des ressources et libération du réceptionniste si besoin
  @override
  void dispose() {
    super.dispose();
    if (_isReceptionist && _receptionistName != null && _selectedHotelId != null && _conversationId != null) {
      FirebaseFirestore.instance.collection('hotels').doc(_selectedHotelId).collection('receptionists').where('name', isEqualTo: _receptionistName).get().then((snap) {
        if (snap.docs.isNotEmpty) {
          snap.docs.first.reference.update({'isAvailable': true, 'currentConversationId': null});
        }
      });
      // Libère la conversation côté Firestore si besoin
      FirebaseFirestore.instance.collection('conversations').doc(_conversationId).update({'assignedReceptionist': null, 'isEscalated': false});
    }
  }

  // Méthode pour écouter les messages en temps réel d'une conversation
  void _listenToMessages(String conversationId) {
    _messagesStream = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
    print('Écoute des messages en temps réel pour la conversation $conversationId');
  }

  // Méthode pour afficher une boîte de dialogue d'erreur
  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => PlatformConfig.navigateToUrl(Environment.webAppUrl, context),
            child: Text('Retour'),
          ),
        ],
      ),
    );
  }

  // Méthode pour retirer les messages d'escalade (boutons Oui/Non) de Firestore
  Future<void> _removeEscalationButtonsMessage() async {
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .where('hasButtons', isEqualTo: true)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // Méthode pour retirer le message temporaire "Bot est en train d'écrire" de Firestore
  Future<void> _removeBotTypingMessage() async {
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .where('isTemporary', isEqualTo: true)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // Méthode pour signaler que le réceptionniste commence à écrire (affichage typing côté client)
  void _onUserTypingStart() async {
    if (!_isReceptionist) return;
    String senderName = _receptionistName ?? 'Réceptionniste';
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .where('isTyping', isEqualTo: true)
        .where('senderName', isEqualTo: senderName)
        .get();
    if (snap.docs.isEmpty) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add({
        'isTyping': true,
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': senderName,
      });
    }
  }

  // Méthode pour signaler que le réceptionniste arrête d'écrire
  void _onUserTypingStop() async {
    if (!_isReceptionist) return;
    String senderName = _receptionistName ?? 'Réceptionniste';
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .where('isTyping', isEqualTo: true)
        .where('senderName', isEqualTo: senderName)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // Widget pour afficher le badge d'escalade si un réceptionniste est en charge
  Widget _buildEscalationBadge() {
    if (_isConversationEscalated && _assignedReceptionistName != null) {
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF0d1a36),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Réceptionniste en charge : $_assignedReceptionistName',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildMessage(ChatMessage message, int index) {
    final isUser      = message.isUser;
    final sender      = message.senderName ?? (isUser ? "Client" : "Bot");
    final isReception = sender == _assignedReceptionistName;
    final alignRight  = isUser;

    if (message.isTemporary) {
      if (!_isReceptionist && message.senderName == "Bot") {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[700],
                child: Icon(Icons.smart_toy, color: Colors.white),
              ),
              SizedBox(width: 10),
              AnimatedDots(sender: "Bot"),
            ],
          ),
        );
      }
      if (_isReceptionist) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isReception ? Colors.grey[900] : Colors.grey[700],
                child: isReception
                    ? Icon(Icons.headset_mic, color: Color(0xFFe2001a))
                    : (isReception
                        ? Icon(Icons.smart_toy, color: Color(0xFFe2001a))
                        : Icon(Icons.person, color: Color(0xFFe2001a))),
              ),
              SizedBox(width: 10),
              AnimatedDots(sender: message.senderName ?? ''),
            ],
          ),
        );
      }
      return SizedBox.shrink();
    }

    // 2) Message permanent
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!alignRight) ...[
            CircleAvatar(
              backgroundColor: isReception ? Colors.grey[900] : Colors.grey[700],
              child: isReception
                  ? Icon(Icons.headset_mic, color: Color(0xFFe2001a))
                  : (isReception
                      ? Icon(Icons.smart_toy, color: Color(0xFFe2001a))
                      : Icon(Icons.person, color: Color(0xFFe2001a))),
            ),
            SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                SizedBox(height: 2),
                Container(
                  padding: EdgeInsets.all(14),
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
                  child: message.hasButtons
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  message.text,
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                            _buildEscalationButtons(),
                          ],
                        )
                      : Text(
                          message.text,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
          if (alignRight) ...[
            SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: Color(0xFFe2001a),
              child: Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

// Classe représentant un message du chat (utilisée pour l'affichage et la logique)
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isTemporary;
  final bool hasButtons;
  final String? senderName;
  final bool isTyping;

  ChatMessage({required this.text, required this.isUser, this.isTemporary = false, this.hasButtons = false, this.senderName, this.isTyping = false});
}

// Fonction utilitaire pour libérer un réceptionniste (remettre disponible)
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

// Widget animé pour afficher les points de "Bot est en train d'écrire..."
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

// Fonction utilitaire pour ouvrir une URL (web ou mobile)
void navigateToUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Impossible d\'ouvrir $url';
  }
}
