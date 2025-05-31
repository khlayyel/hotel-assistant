import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'receptionist_screen.dart';
import 'package:go_router/go_router.dart';

class ReceptionistAuthScreen extends StatefulWidget {
  const ReceptionistAuthScreen({Key? key}) : super(key: key);

  @override
  _ReceptionistAuthScreenState createState() => _ReceptionistAuthScreenState();
}

class _ReceptionistAuthScreenState extends State<ReceptionistAuthScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  String? _targetConversationId;
  String? _targetReceptionistNameFromUrl;
  String? _targetHotelId;

  @override
  void initState() {
    super.initState();
    final goRouterState = GoRouterState.of(context);
    _targetConversationId = goRouterState.uri.queryParameters['conversationId'];
    _targetReceptionistNameFromUrl = goRouterState.uri.queryParameters['receptionistName'];
    _targetHotelId = goRouterState.uri.queryParameters['hotelId'];

    print('DEBUG ReceptionistAuthScreen: initState (Login générique) appelé. Cible - conversationId: $_targetConversationId, receptionistName(URL): $_targetReceptionistNameFromUrl, hotelId: $_targetHotelId');

    if (_targetConversationId == null || _targetConversationId!.isEmpty || _targetHotelId == null || _targetHotelId!.isEmpty) {
         setState(() {
             _error = "Lien de conversation incomplet ou invalide.";
         });
         print('DEBUG ReceptionistAuthScreen: Paramètres de conversation cible manquants dans l\'URL.');
     }
  }

  Future<void> _authenticate() async {
    final enteredUsername = _usernameController.text.trim();
    final enteredPassword = _passwordController.text.trim();

    if (_targetConversationId == null || _targetConversationId!.isEmpty || _targetHotelId == null || _targetHotelId!.isEmpty) {
         setState(() {
             _error = "Impossible de procéder: Informations de conversation cible manquantes.";
             _isLoading = false;
         });
         return;
     }

    if (enteredUsername.isEmpty || enteredPassword.isEmpty) {
      setState(() {
        _error = "Veuillez entrer votre nom d\'utilisateur et mot de passe";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final receptionistQuery = await FirebaseFirestore.instance
          .collectionGroup('receptionists')
          .where('name', isEqualTo: enteredUsername)
          .get();

      if (receptionistQuery.docs.isEmpty) {
        setState(() {
          _error = "Nom d\'utilisateur ou mot de passe incorrect";
          _isLoading = false;
        });
        return;
      }

      DocumentSnapshot? authenticatedReceptionistDoc;
      for (var doc in receptionistQuery.docs) {
          final parentHotelId = doc.reference.parent.parent?.id;
          if (parentHotelId == _targetHotelId) {
              authenticatedReceptionistDoc = doc;
              break;
          }
      }

       if (authenticatedReceptionistDoc == null) {
            setState(() {
              _error = "Nom d\'utilisateur ou mot de passe incorrect pour cet hôtel.";
              _isLoading = false;
            });
            return;
       }

      final receptionistData = authenticatedReceptionistDoc.data() as Map<String, dynamic>?;

       if (receptionistData == null || receptionistData['password'] != enteredPassword) {
        setState(() {
          _error = "Nom d\'utilisateur ou mot de passe incorrect";
          _isLoading = false;
        });
        return;
      }

      final authenticatedReceptionistName = receptionistData['name'];
      print('DEBUG ReceptionistAuthScreen: Authentification réussie pour $authenticatedReceptionistName. Navigation vers conversation cible.');

      context.go('/receptionniste/chat/$_targetConversationId?receptionistName=${Uri.encodeComponent(authenticatedReceptionistName!)}&hotelId=${Uri.encodeComponent(_targetHotelId!)}');

    } catch (e) {
      setState(() {
        _error = "Une erreur est survenue lors de l\'authentification: ${e}";
        _isLoading = false;
      });
      print('Erreur d\'authentification (Login générique): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e), // Bleu foncé
              Color(0xFF0d47a1), // Bleu
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.headset_mic,
                        size: 50,
                        color: Color(0xFFe2001a), // Rouge Hotix
                      ),
                    ),
                    SizedBox(height: 32),

                    Text(
                      "Connexion Réceptionniste",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 32),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: "Nom d\'utilisateur",
                          prefixIcon: Icon(Icons.person, color: Color(0xFFe2001a)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Mot de passe",
                          prefixIcon: Icon(Icons.lock, color: Color(0xFFe2001a)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    if (_error != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFe2001a),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Se connecter",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
} 