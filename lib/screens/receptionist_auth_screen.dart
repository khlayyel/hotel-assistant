import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'receptionist_screen.dart';

class ReceptionistAuthScreen extends StatefulWidget {
  const ReceptionistAuthScreen({Key? key}) : super(key: key);

  @override
  _ReceptionistAuthScreenState createState() => _ReceptionistAuthScreenState();
}

class _ReceptionistAuthScreenState extends State<ReceptionistAuthScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  String? _conversationId;
  String? _receptionistName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args != null) {
        setState(() {
          _conversationId = args['conversationId'];
          _receptionistName = args['receptionistName'];
        });
        print('DEBUG ReceptionistAuthScreen: Arguments de route reçus - conversationId: $_conversationId, receptionistName: $_receptionistName');
      } else {
        setState(() {
           _error = "Informations de conversation manquantes.";
           print('DEBUG ReceptionistAuthScreen: Arguments de route manquants!');
        });
      }
    });
  }

  Future<void> _authenticate() async {
    if (_receptionistName == null || _conversationId == null) {
       setState(() {
          _error = "Les informations nécessaires à l\'authentification sont manquantes.";
       });
       return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _error = "Veuillez entrer votre mot de passe";
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
          .where('name', isEqualTo: _receptionistName)
          .get();

      if (receptionistQuery.docs.isEmpty) {
        setState(() {
          _error = "Réceptionniste non trouvé ou lien invalide";
          _isLoading = false;
        });
        return;
      }

      final receptionistDoc = receptionistQuery.docs.first;
      final receptionistData = receptionistDoc.data();

      if (receptionistData['name'] != _receptionistName) {
        setState(() {
          _error = "Ce lien est réservé à ${_receptionistName}. Veuillez utiliser vos propres identifiants.";
          _isLoading = false;
        });
        return;
      }

      if (receptionistData['password'] != _passwordController.text) {
        setState(() {
          _error = "Mot de passe incorrect";
          _isLoading = false;
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceptionistScreen(
            conversationId: _conversationId!,
            receptionistName: _receptionistName!,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = "Une erreur est survenue lors de l\'authentification.";
        _isLoading = false;
      });
      print('Erreur d\'authentification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_receptionistName == null || _conversationId == null) {
      return Scaffold(
        body: Center(
          child: _error != null ? Text(_error!, style: TextStyle(color: Colors.red)) : CircularProgressIndicator()
        ),
      );
    }

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
                      "Authentification Réceptionniste",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _receptionistName!,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
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
    super.dispose();
  }
} 