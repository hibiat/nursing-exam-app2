import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static Future<User> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) {
      return current;
    }
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }
}
