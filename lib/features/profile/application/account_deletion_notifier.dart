import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class AccountDeletionState {
  const AccountDeletionState({
    this.isDeleting = false,
    this.error,
  });

  final bool isDeleting;
  final String? error;
}

class AccountDeletionNotifier extends Notifier<AccountDeletionState> {
  static const _recentLoginWindow = Duration(minutes: 5);

  @override
  AccountDeletionState build() => const AccountDeletionState();

  Future<bool> deleteAccount() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      state = const AccountDeletionState(error: 'account-sign-in-required');
      return false;
    }

    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null ||
        DateTime.now().difference(lastSignIn) > _recentLoginWindow) {
      state = const AccountDeletionState(
        error: 'account-recent-login-required',
      );
      return false;
    }

    state = const AccountDeletionState(isDeleting: true);
    try {
      await ref.read(userRepositoryProvider).deletePersonalData(user.uid);
      await user.delete();
      state = const AccountDeletionState();
      return true;
    } on fb.FirebaseAuthException catch (error) {
      final code = error.code == 'requires-recent-login'
          ? 'account-recent-login-required'
          : 'account-deletion-failed';
      state = AccountDeletionState(error: code);
      return false;
    } catch (error) {
      state = const AccountDeletionState(error: 'account-deletion-failed');
      return false;
    }
  }
}

final accountDeletionNotifierProvider =
    NotifierProvider<AccountDeletionNotifier, AccountDeletionState>(
  AccountDeletionNotifier.new,
);
