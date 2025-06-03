import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'choose_role_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

// ==========================
// gestion_hotels_screen.dart : Écran principal pour la gestion des hôtels, réceptionnistes et admins
// Permet d'ajouter, modifier, supprimer des hôtels et des utilisateurs
// ==========================

// Importation de la librairie Flutter pour l'UI
import 'package:flutter/material.dart'; // Permet de créer des widgets visuels
// Importation de Firestore pour la gestion des données
import 'package:cloud_firestore/cloud_firestore.dart'; // Accès à la base de données
// Importation de l'écran de choix de rôle (pour retour)
import 'choose_role_screen.dart';

// Widget principal pour la gestion des hôtels et des utilisateurs
class GestionHotelsScreen extends StatefulWidget {
  @override
  _GestionHotelsScreenState createState() => _GestionHotelsScreenState();
}

// Classe d'état associée à GestionHotelsScreen
class _GestionHotelsScreenState extends State<GestionHotelsScreen> with SingleTickerProviderStateMixin {
  // Contrôleurs pour les champs de saisie
  final TextEditingController _hotelController = TextEditingController();
  final TextEditingController _receptionistEmailController = TextEditingController();
  final TextEditingController _receptionistNameController = TextEditingController();
  final TextEditingController _receptionistPasswordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  // Instance Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Variables d'état pour la gestion des hôtels et utilisateurs
  String? _selectedHotelId;
  String? _selectedHotelName;
  List<Map<String, dynamic>> _receptionists = [];
  List<Map<String, dynamic>> _filteredReceptionists = [];
  List<Map<String, dynamic>> _hotelSuggestions = [];
  bool _isLoading = false;
  bool _hotelExists = false;
  bool _showAddReceptionistForm = false;
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _allHotels = [];

  // Pour la gestion des admins
  TabController? _tabController;
  List<Map<String, dynamic>> _admins = [];
  final TextEditingController _adminUsernameController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  bool _showAddAdminForm = false;

  // Variables d'état pour afficher/masquer les mots de passe
  bool _showReceptionistPassword = false;
  bool _showEditReceptionistPassword = false;
  bool _showAdminPassword = false;
  bool _showEditAdminPassword = false;

  @override
  void initState() {
    super.initState();
    // Ajoute les listeners pour la recherche et la saisie d'hôtel
    _searchController.addListener(_filterReceptionists);
    _hotelController.addListener(_onHotelInputChanged);
    _loadAllHotels();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdmins();
  }

  @override
  void dispose() {
    // Libère les ressources des contrôleurs
    _searchController.dispose();
    _hotelController.dispose();
    _receptionistEmailController.dispose();
    _receptionistNameController.dispose();
    _receptionistPasswordController.dispose();
    _tabController?.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  void _onHotelInputChanged() async {
    final input = _hotelController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _hotelSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final querySnapshot = await _firestore
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
      _showSuggestions = true;
    });
  }

  void _selectHotelSuggestion(Map<String, dynamic> hotel) {
    setState(() {
      _hotelController.text = hotel['name'];
      _selectedHotelId = hotel['id'];
      _selectedHotelName = hotel['name'];
      _showSuggestions = false;
      _hotelExists = true;
      _receptionists = [];
      _filteredReceptionists = [];
    });
    _loadReceptionists();
  }

  void _filterReceptionists() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredReceptionists = List.from(_receptionists);
      } else {
        _filteredReceptionists = _receptionists.where((receptionist) {
          final name = (receptionist['name'] ?? '').toLowerCase();
          final emails = (receptionist['emails'] as List<dynamic>? ?? [])
              .map((e) => e['address'].toString().toLowerCase())
              .toList();
          return name.contains(query) || 
                 emails.any((email) => email.contains(query));
        }).toList();
      }
    });
  }

  Future<void> _searchHotel() async {
    setState(() {
      _isLoading = true;
      _hotelExists = false;
      _receptionists = [];
      _filteredReceptionists = [];
    });
    try {
      final querySnapshot = await _firestore
          .collection('hotels')
          .where('name', isEqualTo: _hotelController.text.trim())
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _hotelExists = true;
          _selectedHotelId = querySnapshot.docs.first.id;
          _selectedHotelName = querySnapshot.docs.first.get('name');
          _receptionists = [];
          _filteredReceptionists = [];
        });
        await _loadReceptionists();
      }
    } catch (e) {
      print('❌ Erreur lors de la recherche de l\'hôtel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche de l\'hôtel')),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadReceptionists() async {
    if (_selectedHotelId == null) {
      print('❌ Impossible de charger les réceptionnistes: Aucun hôtel sélectionné');
      return;
    }
    print('Chargement des réceptionnistes pour l\'hôtel: $_selectedHotelName');
    try {
      final querySnapshot = await _firestore
          .collection('hotels')
          .doc(_selectedHotelId)
          .collection('receptionists')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        _receptionists = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _filteredReceptionists = List.from(_receptionists);
      });
      print('✅ ${_receptionists.length} réceptionniste(s) chargé(s) avec succès');
    } catch (e) {
      print('❌ Erreur lors du chargement des réceptionnistes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des réceptionnistes')),
      );
    }
  }

  Future<void> _addHotel() async {
    final hotelName = _hotelController.text.trim();
    if (hotelName.isEmpty) {
      print('❌ Tentative d\'ajout d\'un hôtel sans nom');
      return;
    }

    print('Début de l\'ajout de l\'hôtel: $hotelName');
    try {
      // Vérifier si l'hôtel existe déjà
      final existingHotel = await _firestore
          .collection('hotels')
          .where('name', isEqualTo: hotelName)
          .get();

      if (existingHotel.docs.isNotEmpty) {
        print('❌ L\'hôtel $hotelName existe déjà');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cet hôtel existe déjà')),
        );
        return;
      }

      final docRef = await _firestore.collection('hotels').add({
        'name': hotelName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Hôtel ajouté avec succès. ID: ${docRef.id}');
      setState(() {
        _selectedHotelId = docRef.id;
        _selectedHotelName = hotelName;
        _hotelExists = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hôtel ajouté avec succès')),
      );
      _hotelController.clear();
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de l\'hôtel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'hôtel')),
      );
    }
  }

  Future<String> encryptPassword(String password) async {
    final response = await http.post(
      Uri.parse(Environment.apiBaseUrl + '/encrypt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['encrypted'];
    } else {
      throw Exception('Erreur de chiffrement');
    }
  }

  Future<String> decryptPassword(String encrypted) async {
    final response = await http.post(
      Uri.parse(Environment.apiBaseUrl + '/decrypt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'encrypted': encrypted}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['decrypted'];
    } else {
      throw Exception('Erreur de déchiffrement');
    }
  }

  Future<void> _addReceptionist() async {
    if (_selectedHotelId == null) {
      print('❌ Impossible d\'ajouter un réceptionniste: Aucun hôtel sélectionné');
      return;
    }
    final name = _receptionistNameController.text.trim();
    final email = _receptionistEmailController.text.trim();
    final password = _receptionistPasswordController.text.trim();
    
    if (name.isEmpty) {
      print('❌ Nom du réceptionniste manquant');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le nom du réceptionniste est obligatoire')),
      );
      return;
    }
    if (email.isEmpty || !_isValidEmail(email)) {
      print('❌ Email du réceptionniste manquant ou invalide');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('L\'adresse email du réceptionniste est obligatoire et doit être valide')),
      );
      return;
    }
    if (password.isEmpty || password.length < 6) {
      print('❌ Mot de passe invalide');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')),
      );
      return;
    }

    print('Début de l\'ajout du réceptionniste - Nom: $name, Email: $email');
    try {
      final encryptedPassword = await encryptPassword(password);
      final docRef = await _firestore
          .collection('hotels')
          .doc(_selectedHotelId)
          .collection('receptionists')
          .add({
        'name': name,
        'password': encryptedPassword,
        'emails': [
          {
            'address': email,
            'createdAt': DateTime.now(),
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'isAvailable': true,
      });
      await _loadReceptionists();
      _receptionistNameController.clear();
      _receptionistEmailController.clear();
      _receptionistPasswordController.clear();
      setState(() {
        _showAddReceptionistForm = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réceptionniste ajouté avec succès')),
      );
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du réceptionniste: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du réceptionniste')),
      );
    }
  }

  Future<void> _addEmailToReceptionist(String receptionistId, String receptionistName, [String? email, bool showDialogOnError = false]) async {
    String? emailToAdd = email;
    if (emailToAdd == null) {
      final TextEditingController emailController = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ajouter un email'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Adresse email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, emailController.text.trim());
              },
              child: Text('Ajouter'),
            ),
          ],
        ),
      );
      emailToAdd = result;
    }
    if (emailToAdd == null || !_isValidEmail(emailToAdd)) {
      if (showDialogOnError || email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Adresse email invalide')),
        );
      }
      return;
    }
    try {
      final receptionistRef = _firestore
          .collection('hotels')
          .doc(_selectedHotelId)
          .collection('receptionists')
          .doc(receptionistId);
      final receptionistDoc = await receptionistRef.get();
      final currentEmails = List<Map<String, dynamic>>.from(
          receptionistDoc.data()?['emails'] ?? []);
      if (currentEmails.any((e) => e['address'] == emailToAdd)) {
        if (showDialogOnError || email == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cet email existe déjà')),
          );
        }
        return;
      }
      currentEmails.add({
        'address': emailToAdd,
        'createdAt': DateTime.now(),
      });
      await receptionistRef.update({'emails': currentEmails});
      print('✅ Email ajouté avec succès: $emailToAdd');
      await _loadReceptionists();
      if (showDialogOnError || email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email ajouté avec succès')),
        );
        if (email == null) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de l\'email: $e');
      if (showDialogOnError || email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de l\'email')),
        );
      }
      await _loadReceptionists();
    }
  }

  Future<void> _deleteReceptionist(String receptionistId, String receptionistName) async {
    if (_selectedHotelId == null) {
      print('❌ Impossible de supprimer le réceptionniste: Aucun hôtel sélectionné');
      return;
    }

    print('Début de la suppression du réceptionniste: $receptionistName (ID: $receptionistId)');
    try {
      await _firestore
          .collection('hotels')
          .doc(_selectedHotelId)
          .collection('receptionists')
          .doc(receptionistId)
          .delete();

      print('✅ Réceptionniste supprimé avec succès');
      await _loadReceptionists();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réceptionniste supprimé avec succès')),
      );
    } catch (e) {
      print('❌ Erreur lors de la suppression du réceptionniste: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression du réceptionniste')),
      );
    }
  }

  Future<void> _editHotel() async {
    if (_selectedHotelId == null) {
      print('❌ Impossible de modifier l\'hôtel: Aucun hôtel sélectionné');
      return;
    }

    print('Début de la modification de l\'hôtel: $_selectedHotelName');
    final TextEditingController editController = TextEditingController(text: _selectedHotelName);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier l\'hôtel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              decoration: InputDecoration(
                labelText: 'Nouveau nom',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = editController.text.trim();
              if (newName.isEmpty) return;

              try {
                await _firestore
                    .collection('hotels')
                    .doc(_selectedHotelId)
                    .update({'name': newName});
                
                print('✅ Hôtel modifié avec succès: $newName');
                setState(() {
                  _selectedHotelName = newName;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hôtel modifié avec succès')),
                );
              } catch (e) {
                print('❌ Erreur lors de la modification de l\'hôtel: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la modification')),
                );
              }
              Navigator.pop(context);
            },
            child: Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHotel() async {
    if (_selectedHotelId == null) {
      print('❌ Impossible de supprimer l\'hôtel: Aucun hôtel sélectionné');
      return;
    }

    print('Début de la suppression de l\'hôtel: $_selectedHotelName');
    
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'hôtel'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet hôtel et tous ses réceptionnistes ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        // Supprimer tous les réceptionnistes d'abord
        final receptionistsSnapshot = await _firestore
            .collection('hotels')
            .doc(_selectedHotelId)
            .collection('receptionists')
            .get();
        
        for (var doc in receptionistsSnapshot.docs) {
          await doc.reference.delete();
        }

        // Puis supprimer l'hôtel
        await _firestore.collection('hotels').doc(_selectedHotelId).delete();
        
        print('✅ Hôtel et ses réceptionnistes supprimés avec succès');
        setState(() {
          _selectedHotelId = null;
          _selectedHotelName = null;
          _hotelExists = false;
          _receptionists = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hôtel supprimé avec succès')),
        );
      } catch (e) {
        print('❌ Erreur lors de la suppression de l\'hôtel: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    }
  }

  Future<void> _editReceptionist(Map<String, dynamic> receptionist) async {
    print('Début de la modification du réceptionniste: ${receptionist['name']}');
    final TextEditingController nameController = TextEditingController(text: receptionist['name']);
    final TextEditingController passwordController = TextEditingController(text: receptionist['password'] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le réceptionniste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setStateDialog) {
                return TextField(
                  controller: passwordController,
                  obscureText: !_showEditReceptionistPassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: Color(0xFFe2001a)),
                    suffixIcon: IconButton(
                      icon: Icon(_showEditReceptionistPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () {
                        setStateDialog(() { _showEditReceptionistPassword = !_showEditReceptionistPassword; });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newPassword = passwordController.text.trim();
              
              if (newName.isEmpty) return;
              if (newPassword.isEmpty || newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')),
                );
                return;
              }
              
              try {
                final newEncryptedPassword = await encryptPassword(newPassword);
                await _firestore
                    .collection('hotels')
                    .doc(_selectedHotelId)
                    .collection('receptionists')
                    .doc(receptionist['id'])
                    .update({
                  'name': newName,
                  'password': newEncryptedPassword,
                });
                print('✅ Réceptionniste modifié avec succès: $newName');
                await _loadReceptionists();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Réceptionniste modifié avec succès')),
                );
              } catch (e) {
                print('❌ Erreur lors de la modification du réceptionniste: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la modification')),
                );
              }
              Navigator.pop(context);
            },
            child: Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _editEmail(String receptionistId, Map<String, dynamic> emailData, int index) async {
    final TextEditingController emailController = TextEditingController(text: emailData['address']);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier l\'email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Adresse email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = emailController.text.trim();
              if (!_isValidEmail(newEmail)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Adresse email invalide')),
                );
                return;
              }

              try {
                final receptionistRef = _firestore
                    .collection('hotels')
                    .doc(_selectedHotelId)
                    .collection('receptionists')
                    .doc(receptionistId);

                final receptionistDoc = await receptionistRef.get();
                final emails = List<Map<String, dynamic>>.from(
                    receptionistDoc.data()?['emails'] ?? []);

                if (emails.any((e) => e['address'] == newEmail && emails.indexOf(e) != index)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cet email existe déjà')),
                  );
                  return;
                }

                emails[index] = {
                  'address': newEmail,
                  'createdAt': emailData['createdAt'],
                };

                await receptionistRef.update({'emails': emails});
                print('✅ Email modifié avec succès: $newEmail');
                await _loadReceptionists();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Email modifié avec succès')),
                );
              } catch (e) {
                print('❌ Erreur lors de la modification de l\'email: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la modification de l\'email')),
                );
              }
            },
            child: Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmail(String receptionistId, int emailIndex) async {
    try {
      final receptionistRef = _firestore
          .collection('hotels')
          .doc(_selectedHotelId)
          .collection('receptionists')
          .doc(receptionistId);

      final receptionistDoc = await receptionistRef.get();
      final emails = List<Map<String, dynamic>>.from(
          receptionistDoc.data()?['emails'] ?? []);

      emails.removeAt(emailIndex);
      await receptionistRef.update({'emails': emails});
      print('✅ Email supprimé avec succès');
      await _loadReceptionists();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email supprimé avec succès')),
      );
    } catch (e) {
      print('❌ Erreur lors de la suppression de l\'email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression de l\'email')),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  Widget _buildEmailsList(Map<String, dynamic> receptionist) {
    final emails = List<Map<String, dynamic>>.from(receptionist['emails'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emails.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Aucun email',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
        ...emails.asMap().entries.map((entry) {
          final index = entry.key;
          final email = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(email['address']),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _editEmail(receptionist['id'], email, index),
                  tooltip: 'Modifier l\'email',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _deleteEmail(receptionist['id'], index),
                  tooltip: 'Supprimer l\'email',
                ),
              ],
            ),
          );
        }).toList(),
        TextButton.icon(
          icon: Icon(Icons.add),
          label: Text('Ajouter un email'),
          onPressed: () => _addEmailToReceptionist(
            receptionist['id'],
            receptionist['name'],
          ),
        ),
      ],
    );
  }

  Future<void> _loadAllHotels() async {
    final querySnapshot = await _firestore
        .collection('hotels')
        .orderBy('name')
        .get();
    setState(() {
      _allHotels = querySnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name']})
          .toList();
    });
  }

  Future<void> _loadAdmins() async {
    final querySnapshot = await _firestore.collection('admins').get();
    setState(() {
      _admins = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  Future<void> _addAdmin() async {
    final username = _adminUsernameController.text.trim();
    final password = _adminPasswordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tous les champs sont obligatoires')),
      );
      return;
    }
    try {
      final encryptedAdminPassword = await encryptPassword(password);
      await _firestore.collection('admins').add({
        'username': username,
        'password': encryptedAdminPassword,
      });
      _adminUsernameController.clear();
      _adminPasswordController.clear();
      setState(() { _showAddAdminForm = false; });
      await _loadAdmins();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin ajouté avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'admin')),
      );
    }
  }

  Future<void> _deleteAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).delete();
      await _loadAdmins();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin supprimé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression de l\'admin')),
      );
    }
  }

  Future<void> _editAdmin(Map<String, dynamic> admin) async {
    final TextEditingController usernameController = TextEditingController(text: admin['username']);
    final TextEditingController passwordController = TextEditingController(text: admin['password'] ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier l\'admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Nom d\'utilisateur',
                hintText: 'Nom d\'utilisateur',
                hintStyle: TextStyle(color: Color(0xFF0d1a36).withOpacity(0.5)),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: Color(0xFF1976d2)),
              ),
            ),
            SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setStateDialog) {
                return TextField(
                  controller: passwordController,
                  obscureText: !_showEditAdminPassword,
                  style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Mot de passe',
                    hintStyle: TextStyle(color: Color(0xFF0d1a36).withOpacity(0.5)),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF1976d2)),
                    suffixIcon: IconButton(
                      icon: Icon(_showEditAdminPassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF1976d2)),
                      onPressed: () {
                        setStateDialog(() { _showEditAdminPassword = !_showEditAdminPassword; });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              final newPassword = passwordController.text.trim();
              if (newUsername.isEmpty || newPassword.isEmpty) return;
              try {
                final newEncryptedAdminPassword = await encryptPassword(newPassword);
                await _firestore.collection('admins').doc(admin['id']).update({
                  'username': newUsername,
                  'password': newEncryptedAdminPassword,
                });
                await _loadAdmins();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Admin modifié avec succès')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la modification de l\'admin')),
                );
              }
            },
            child: Text('Modifier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Gestion des Hôtels'),
        backgroundColor: Color(0xFF0d1a36),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ChooseRoleScreen()),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Hôtels'),
            Tab(text: 'Admins'),
          ],
          labelColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          unselectedLabelColor: Colors.black54,
        ),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            // Onglet Hôtels
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isMobile ? 400 : 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    if (_allHotels.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedHotelId,
                                          isExpanded: true,
                                          items: _allHotels.map((hotel) {
                                            return DropdownMenuItem<String>(
                                              value: hotel['id'],
                                              child: Text(hotel['name']),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedHotelId = value;
                                              final selected = _allHotels.firstWhere((h) => h['id'] == value);
                                              _selectedHotelName = selected['name'];
                                              _hotelController.text = selected['name'];
                                            });
                                          },
                                          decoration: InputDecoration(
                                            labelText: "Sélectionner un hôtel",
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.hotel, color: Color(0xFFe2001a)),
                                          ),
                                        ),
                                      ),
                                    TextField(
                                      controller: _hotelController,
                                      style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                        labelText: 'Entrer le nom de l\'hôtel',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.hotel, color: Color(0xFF1976d2)),
                                      ),
                                    ),
                                    if (_showSuggestions && _hotelSuggestions.isNotEmpty)
                                      Container(
                                        margin: EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Color(0xFFe2001a)),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _hotelSuggestions.length,
                                          itemBuilder: (context, index) {
                                            final hotel = _hotelSuggestions[index];
                                            return ListTile(
                                              title: Text(hotel['name']),
                                              onTap: () => _selectHotelSuggestion(hotel),
                                            );
                                          },
                                        ),
                                      ),
                                    SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _searchHotel,
                                      icon: Icon(Icons.search),
                                      label: Text('Rechercher'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFe2001a),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedHotelName != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hôtel: $_selectedHotelName',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Color(0xFFe2001a)),
                                      onPressed: _editHotel,
                                      tooltip: 'Modifier l\'hôtel',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: _deleteHotel,
                                      tooltip: 'Supprimer l\'hôtel',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 16),
                        if (_isLoading)
                          Center(child: CircularProgressIndicator())
                        else if (_hotelExists) ...[
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: 'Rechercher un réceptionniste',
                                  hintText: 'Rechercher par nom ou email',
                                  hintStyle: TextStyle(color: Color(0xFF0d1a36).withOpacity(0.5)),
                                  prefixIcon: Icon(Icons.search, color: Color(0xFF1976d2)),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            child: Container(
                              constraints: BoxConstraints(
                                minHeight: 200,
                                maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.6 : 500,
                              ),
                              child: _filteredReceptionists.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Center(
                                        child: Text(
                                          'Aucun réceptionniste pour cet hôtel',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Scrollbar(
                                      thumbVisibility: true,
                                      child: ListView.builder(
                                        itemCount: _filteredReceptionists.length,
                                        itemBuilder: (context, index) {
                                          final receptionist = _filteredReceptionists[index];
                                          return ExpansionTile(
                                            leading: CircleAvatar(
                                              child: Icon(Icons.person, color: Colors.white),
                                              backgroundColor: Color(0xFF1976d2),
                                            ),
                                            title: Text(receptionist['name'] ?? 'Sans nom', style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.bold)),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit, color: Color(0xFF1976d2)),
                                                  onPressed: () => _editReceptionist(receptionist),
                                                  tooltip: 'Modifier',
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Color(0xFF1976d2)),
                                                  onPressed: () => _deleteReceptionist(
                                                    receptionist['id'],
                                                    receptionist['name'] ?? 'Sans nom',
                                                  ),
                                                  tooltip: 'Supprimer',
                                                ),
                                              ],
                                            ),
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(16.0),
                                                child: _buildEmailsList(receptionist),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              children: [
                                if (!_showAddReceptionistForm)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _showAddReceptionistForm = true;
                                        _receptionistNameController.clear();
                                      });
                                    },
                                    icon: Icon(Icons.add),
                                    label: Text('Ajouter un réceptionniste'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFe2001a),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                if (_showAddReceptionistForm) ...[
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: _receptionistNameController,
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                            decoration: InputDecoration(
                                              labelText: 'Nom du réceptionniste',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.person, color: Color(0xFFe2001a)),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          TextField(
                                            controller: _receptionistEmailController,
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                            decoration: InputDecoration(
                                              labelText: 'Email du réceptionniste (obligatoire)',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.email, color: Color(0xFFe2001a)),
                                            ),
                                            keyboardType: TextInputType.emailAddress,
                                          ),
                                          SizedBox(height: 8),
                                          TextField(
                                            controller: _receptionistPasswordController,
                                            obscureText: !_showReceptionistPassword,
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                            decoration: InputDecoration(
                                              labelText: 'Mot de passe (minimum 6 caractères)',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.lock, color: Color(0xFFe2001a)),
                                              suffixIcon: IconButton(
                                                icon: Icon(_showReceptionistPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                                onPressed: () {
                                                  setState(() { _showReceptionistPassword = !_showReceptionistPassword; });
                                                },
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: _addReceptionist,
                                            icon: Icon(Icons.check),
                                            label: Text('Valider'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFFe2001a),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _showAddReceptionistForm = false;
                                                _receptionistNameController.clear();
                                                _receptionistEmailController.clear();
                                                _receptionistPasswordController.clear();
                                              });
                                            },
                                            child: Text('Annuler'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ]
                        else if (_hotelController.text.isNotEmpty)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Hôtel introuvable',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _addHotel,
                                    icon: Icon(Icons.add),
                                    label: Text('Ajouter Hôtel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFe2001a),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Onglet Admins
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isMobile ? 400 : 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Gestion des Admins', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() { _showAddAdminForm = !_showAddAdminForm; });
                              },
                              icon: Icon(Icons.add),
                              label: Text(_showAddAdminForm ? 'Annuler' : 'Ajouter un admin'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1976d2),
                                foregroundColor: Colors.white,
                                textStyle: TextStyle(fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        ),
                        if (_showAddAdminForm)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _adminUsernameController,
                                      style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                        labelText: 'Nom d\'utilisateur',
                                        hintText: 'Nom d\'utilisateur',
                                        hintStyle: TextStyle(color: Color(0xFF0d1a36).withOpacity(0.5)),
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.person, color: Color(0xFF1976d2)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    StatefulBuilder(
                                      builder: (context, setStateDialog) {
                                        return TextField(
                                          controller: _adminPasswordController,
                                          obscureText: !_showAdminPassword,
                                          style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.w600),
                                          decoration: InputDecoration(
                                            labelText: 'Mot de passe',
                                            hintText: 'Mot de passe',
                                            hintStyle: TextStyle(color: Color(0xFF0d1a36).withOpacity(0.5)),
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.lock, color: Color(0xFF1976d2)),
                                            suffixIcon: IconButton(
                                              icon: Icon(_showAdminPassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF1976d2)),
                                              onPressed: () {
                                                setStateDialog(() { _showAdminPassword = !_showAdminPassword; });
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: _addAdmin,
                                      icon: Icon(Icons.check),
                                      label: Text('Valider'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFe2001a),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: _admins.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Center(child: Text('Aucun admin', style: TextStyle(color: Colors.grey))),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _admins.length,
                                  itemBuilder: (context, index) {
                                    final admin = _admins[index];
                                    return ListTile(
                                      leading: Icon(Icons.admin_panel_settings, color: Colors.white),
                                      title: Text(admin['username'] ?? '', style: TextStyle(color: Color(0xFF0d1a36), fontWeight: FontWeight.bold, fontSize: 16)),
                                      subtitle: Text('Mot de passe : ${admin['password'] ?? ''}', style: TextStyle(color: Colors.black87)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: Color(0xFF1976d2), size: 26),
                                            onPressed: () => _editAdmin(admin),
                                            tooltip: 'Modifier',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Color(0xFF1976d2), size: 26),
                                            onPressed: () => _deleteAdmin(admin['id']),
                                            tooltip: 'Supprimer',
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 