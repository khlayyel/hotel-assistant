import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'receptionist_screen.dart';

class ReceptionistAuthScreen extends StatefulWidget {
  final String conversationId;
  final String receptionistName;

  const ReceptionistAuthScreen({
    Key? key,
    required this.conversationId,
    required this.receptionistName,
  }) : super(key: key);

  @override
  _ReceptionistAuthScreenState createState() => _ReceptionistAuthScreenState();
}

class _ReceptionistAuthScreenState extends State<ReceptionistAuthScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  Future<void> _authenticate() async {
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
      // Récupérer le réceptionniste depuis Firestore
      final receptionistQuery = await FirebaseFirestore.instance
          .collectionGroup('receptionists')
          .where('name', isEqualTo: widget.receptionistName)
          .get();

      if (receptionistQuery.docs.isEmpty) {
        setState(() {
          _error = "Réceptionniste non trouvé";
          _isLoading = false;
        });
        return;
      }

      final receptionistDoc = receptionistQuery.docs.first;
      final receptionistData = receptionistDoc.data();

      if (receptionistData['password'] != _passwordController.text) {
        setState(() {
          _error = "Mot de passe incorrect";
          _isLoading = false;
        });
        return;
      }

      // Authentification réussie
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceptionistScreen(
            conversationId: widget.conversationId,
            receptionistName: widget.receptionistName,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = "Une erreur est survenue";
        _isLoading = false;
      });
      print('Erreur d\'authentification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: BoxConstraints(maxWidth: isMobile ? 400 : 380),
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color(0xFF0d1a36),
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
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 28),
                      Text(
                        "Authentification Réceptionniste",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0d1a36),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        widget.receptionistName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF0d1a36),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Mot de passe",
                          hintStyle: TextStyle(color: Color(0xFF1976d2)),
                          prefixIcon: Icon(Icons.lock, color: Color(0xFF0d1a36)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Color(0xFF1976d2),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Color(0xFF0d1a36), width: 1.2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 18),
                      if (_error != null)
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFF1976d2).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFF1976d2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Color(0xFF1976d2)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Color(0xFF1976d2), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _authenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0d1a36),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                              : Text("Se connecter"),
                        ),
                      ),
                    ],
                  ),
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