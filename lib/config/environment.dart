// ==========================
// environment.dart : Configuration des URLs, constantes et messages d'erreur
// ==========================

// Classe de configuration globale pour l'application
class Environment {
  // IMPORTANT : Remplace cette URL par l'URL publique de ton backend Node.js déployé (Render, Railway, etc.)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hotel-assistant.onrender.com/api'
  );
  // URL de l'application web (front-end)
  static const String webAppUrl = String.fromEnvironment(
    'WEB_APP_URL',
    defaultValue: 'https://hotel-assistant-mauve.vercel.app/'
  );
  // Nombre maximal de tentatives pour une opération
  static const int maxRetries = 30;
  // Délai entre chaque tentative
  static const Duration retryDelay = Duration(seconds: 1);
  // Délai maximal avant timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Indique si l'application est en mode développement
  static const bool isDevelopment = true;
  
  // Active ou non les logs détaillés
  static const bool enableLogging = true;
  
  // Durée de validité du cache
  static const Duration cacheDuration = Duration(minutes: 30);
  
  // Message d'erreur par défaut
  static const String defaultErrorMessage = 'Une erreur est survenue. Veuillez réessayer.';
  // Message d'erreur réseau
  static const String networkErrorMessage = 'Problème de connexion. Vérifiez votre connexion internet.';
  // Message d'erreur en cas de timeout
  static const String timeoutErrorMessage = 'Le serveur met trop de temps à répondre. Veuillez réessayer.';
} 