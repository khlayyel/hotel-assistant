// ==========================
// platform_config.dart : Gestion de la navigation et du nettoyage de session selon la plateforme
// ==========================

// Importation pour détecter la plateforme (web ou mobile)
import 'package:flutter/foundation.dart';
// Importation pour ouvrir des liens externes sur le web ou mobile
import 'package:url_launcher/url_launcher.dart';
// Importation de la librairie Flutter pour l'UI et la navigation
import 'package:flutter/material.dart';
// Importation de l'écran de choix de rôle (pour retour sur mobile)
import '../screens/choose_role_screen.dart';
// Importation pour la gestion des préférences locales
import 'package:shared_preferences/shared_preferences.dart';

// Classe utilitaire pour la configuration de la plateforme
class PlatformConfig {
  // Méthode statique pour naviguer vers une URL et nettoyer la session
  static Future<void> navigateToUrl(String url, BuildContext context) async {
    // Nettoyer les données de session (nom, prénom, hôtel)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('clientNom');
    await prefs.remove('clientPrenom');
    await prefs.remove('clientHotelId');
    await prefs.remove('clientHotelName');

    if (kIsWeb) {
      // Sur le web, on utilise url_launcher pour ouvrir l'URL
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Impossible d\'ouvrir $url';
      }
    } else {
      // Sur mobile, on navigue vers l'écran de choix de rôle
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChooseRoleScreen()),
      );
    }
  }

  // Méthode statique pour exécuter une fonction avant que la page ne soit déchargée (web uniquement)
  static void onBeforeUnload(Function(dynamic) callback) {
    // Cette fonctionnalité n'est pas disponible sur mobile
    if (kIsWeb) {
      // Sur le web, on ne fait rien car c'est géré différemment
      return;
    }
  }
} 