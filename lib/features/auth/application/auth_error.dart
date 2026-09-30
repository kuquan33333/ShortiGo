import 'package:firebase_auth/firebase_auth.dart' as fb;

String authErrorCode(Object error) {
  if (error is! fb.FirebaseAuthException) return 'auth-unknown';
  return switch (error.code) {
    'invalid-email' => 'auth-invalid-email',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' =>
      'auth-invalid-credential',
    'email-already-in-use' => 'auth-email-in-use',
    'weak-password' => 'auth-weak-password',
    'too-many-requests' => 'auth-too-many-requests',
    'network-request-failed' => 'auth-network',
    'user-disabled' => 'auth-user-disabled',
    'operation-not-allowed' => 'auth-unavailable',
    _ => 'auth-unknown',
  };
}
