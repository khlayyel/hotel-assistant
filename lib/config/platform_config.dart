import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../screens/choose_role_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlatformConfig {
  static Future<void> navigateToUrl(String url, BuildContext context) async {
    // Nettoyer les données de session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('clientNom');
    await prefs.remove('clientPrenom');
    await prefs.remove('clientHotelId');
    await prefs.remove('clientHotelName');

    if (kIsWeb) {
      // Sur le web, on utilise url_launcher
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Impossible d\'ouvrir $url';
      }
    } else {
      // Sur mobile, on navigue vers ChooseRoleScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChooseRoleScreen()),
      );
    }
  }

  static void onBeforeUnload(Function(dynamic) callback) {
    // Cette fonctionnalité n'est pas disponible sur mobile
    if (kIsWeb) {
      // Sur le web, on ne fait rien car c'est géré différemment
      return;
    }
  }
} 