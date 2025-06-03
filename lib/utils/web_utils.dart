// ==========================
// web_utils.dart : Fonctions utilitaires spécifiques au web
// ==========================

// Importation de la librairie dart:html pour manipuler le navigateur web
import 'dart:html' as html;

// Classe utilitaire pour les fonctions spécifiques au web
class WebUtils {
  // Méthode statique pour naviguer vers une URL (remplace la page courante)
  static void navigateToUrl(String url) {
    html.window.location.href = url;
  }

  // Méthode statique pour exécuter une fonction avant que la page ne soit déchargée (fermeture/rafraîchissement)
  static void onBeforeUnload(Function(dynamic) callback) {
    html.window.onBeforeUnload.listen(callback);
  }
} 