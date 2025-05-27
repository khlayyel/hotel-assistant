import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformUtils {
  static Future<void> navigateToUrl(String url) async {
    if (kIsWeb) {
      // Sur le web, on utilise window.location
      // Cette partie sera gérée différemment dans le code web
      return;
    } else {
      // Sur mobile, on utilise url_launcher
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Impossible d\'ouvrir $url';
      }
    }
  }
} 