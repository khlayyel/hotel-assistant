// ==========================
// platform_utils.dart : Fonctions utilitaires pour la navigation selon la plateforme
// ==========================

// Importation pour détecter la plateforme (web ou mobile)
import 'package:flutter/foundation.dart';
// Importation pour ouvrir des liens externes sur mobile
import 'package:url_launcher/url_launcher.dart';

// Classe utilitaire pour la gestion de la navigation selon la plateforme
class PlatformUtils {
  // Méthode statique pour naviguer vers une URL
  static Future<void> navigateToUrl(String url) async {
    if (kIsWeb) {
      // Sur le web, on utilise window.location (géré ailleurs)
      // Cette partie sera gérée différemment dans le code web
      return;
    } else {
      // Sur mobile, on utilise url_launcher pour ouvrir l'URL
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Impossible d\'ouvrir $url';
      }
    }
  }
} 