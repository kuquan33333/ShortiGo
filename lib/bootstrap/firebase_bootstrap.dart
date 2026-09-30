import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../core/env/env.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool isAvailable = false;

  static Future<bool> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        isAvailable = true;
        return true;
      }
      if (env.isProd) {
        await Firebase.initializeApp(
          options: prod.DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp(
          options: dev.DefaultFirebaseOptions.currentPlatform,
        );
      }
      isAvailable = true;
    } on Object catch (error, stackTrace) {
      isAvailable = false;
      debugPrint('Firebase is unavailable; continuing in guest mode: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return isAvailable;
  }
}
