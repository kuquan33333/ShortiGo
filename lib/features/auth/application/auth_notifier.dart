import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/providers.dart';
import '../../../bootstrap/firebase_bootstrap.dart';
import 'auth_error.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  final fb.User? user;
  final bool isLoading;
  final String? error;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final auth = ref.watch(currentAuthUserProvider).value;
    return AuthState(user: auth);
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (!_ensureFirebase()) return;
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    try {
      final cred = await ref
          .read(firebaseAuthProvider)
          .signInWithEmailAndPassword(email: email, password: password);
      state = AsyncData(AuthState(user: cred.user));
    } catch (error) {
      state = AsyncData(AuthState(error: authErrorCode(error)));
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    if (!_ensureFirebase()) return;
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    try {
      final cred = await ref
          .read(firebaseAuthProvider)
          .createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.sendEmailVerification();
      state = AsyncData(AuthState(user: cred.user));
    } catch (error) {
      state = AsyncData(AuthState(error: authErrorCode(error)));
    }
  }

  Future<void> signInWithGoogle() async {
    if (!_ensureFirebase()) return;
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = AsyncData(
          AuthState(user: ref.read(currentAuthUserProvider).value),
        );
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred =
          await ref.read(firebaseAuthProvider).signInWithCredential(credential);
      state = AsyncData(AuthState(user: cred.user));
    } catch (error) {
      state = AsyncData(AuthState(error: authErrorCode(error)));
    }
  }

  Future<void> signOut() async {
    if (!FirebaseBootstrap.isAvailable) return;
    await ref.read(firebaseAuthProvider).signOut();
    state = const AsyncData(AuthState());
  }

  bool _ensureFirebase() {
    if (FirebaseBootstrap.isAvailable) return true;
    state = const AsyncData(
      AuthState(error: 'account-service-unavailable'),
    );
    return false;
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
