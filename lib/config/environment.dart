class Environment {
  // IMPORTANT : Remplace cette URL par l'URL publique de ton backend Node.js déployé (Render, Railway, etc.)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hotel-assistant.onrender.com/api'
  );
  static const String webAppUrl = String.fromEnvironment(
    'WEB_APP_URL',
    defaultValue: 'https://hotel-assistant-mauve.vercel.app/'
  );
  static const int maxRetries = 30;
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration timeout = Duration(seconds: 30);
  
  // Configuration pour le développement
  static const bool isDevelopment = true;
  
  // Configuration pour les logs
  static const bool enableLogging = true;
  
  // Configuration pour le cache
  static const Duration cacheDuration = Duration(minutes: 30);
  
  // Configuration pour les erreurs
  static const String defaultErrorMessage = 'Une erreur est survenue. Veuillez réessayer.';
  static const String networkErrorMessage = 'Problème de connexion. Vérifiez votre connexion internet.';
  static const String timeoutErrorMessage = 'Le serveur met trop de temps à répondre. Veuillez réessayer.';
} 