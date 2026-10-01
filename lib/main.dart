import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'bootstrap/firebase_bootstrap.dart';
import 'core/env/env.dart';
import 'core/router/app_router.dart';
import 'core/providers.dart';
import 'data/firestore/user_repository.dart';
import 'domain/entities/user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  initializeEnv(Env.fromDefines());
  if (env.hasReleaseBlockingIssues) {
    debugPrint(
      'ShortiGo release blockers:\n'
      '${env.releaseBlockingIssues.map((issue) => '- $issue').join('\n')}',
    );
  }
  final firebaseAvailable = await FirebaseBootstrap.initialize();
  if (firebaseAvailable) {
    unawaited(
      FirebasePerformance.instance.setPerformanceCollectionEnabled(true),
    );
  }
  SystemChannels.system.setMessageHandler((message) async {
    if (message == 'memoryPressure') {
      debugPrint('Memory pressure warning received');
    }
    return null;
  });
  if (firebaseAvailable) {
    fb.FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }
  runApp(
    ProviderScope(child: ShortiGoApp(router: buildRouter(requireAuth: false))),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (env.sentryDsn.isNotEmpty) {
      await SentryFlutter.init((options) {
        options.dsn = env.sentryDsn;
      });
    }
    if (!env.vipTestMode) {
      await revenueCatGateway.initialize(
        appleApiKey: env.revenueCatApiKeyIos,
        googleApiKey: env.revenueCatApiKeyAndroid,
      );
    }
  });
}

Future<void> _onAuthStateChanged(fb.User? user) async {
  if (user == null || !FirebaseBootstrap.isAvailable) {
    return;
  }

  try {
    final db = FirebaseFirestore.instance;
    await FirestoreUserRepository(db).createIfMissing(
      AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  } on Object catch (error, stackTrace) {
    debugPrint('Unable to initialize the Firebase user document: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
