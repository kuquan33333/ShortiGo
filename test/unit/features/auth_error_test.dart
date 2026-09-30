import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/features/auth/application/auth_error.dart';

void main() {
  test('maps common Firebase Auth failures to presentation codes', () {
    expect(
      authErrorCode(FirebaseAuthException(code: 'invalid-email')),
      'auth-invalid-email',
    );
    expect(
      authErrorCode(FirebaseAuthException(code: 'wrong-password')),
      'auth-invalid-credential',
    );
    expect(
      authErrorCode(FirebaseAuthException(code: 'network-request-failed')),
      'auth-network',
    );
    expect(authErrorCode(StateError('unknown')), 'auth-unknown');
  });
}
