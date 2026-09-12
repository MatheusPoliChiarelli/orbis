import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;

  static Stream<User?> get authState => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
  }

  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static String messageForError(Object error) {
    if (error is! FirebaseAuthException) {
      return 'Não foi possível concluir. Tente novamente';
    }
    switch (error.code) {
      case 'invalid-email':
        return 'E-mail inválido';
      case 'user-disabled':
        return 'Esta conta está desativada';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento';
      case 'network-request-failed':
        return 'Sem conexão com a internet';
      default:
        return 'Não foi possível concluir. Tente novamente';
    }
  }
}