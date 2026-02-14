import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  /// 現在のユーザーを取得（ログインしていない場合はnull）
  static User? get currentUser => _auth.currentUser;

  /// 認証状態の変更を監視するStream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Google Sign-In
  static Future<User> signInWithGoogle() async {
    try {
      // Google Sign-In フロー
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-Inがキャンセルされました');
      }

      // 認証情報を取得
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase認証情報を作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseにサインイン
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('認証に失敗しました');
      }

      return userCredential.user!;
    } catch (e) {
      rethrow;
    }
  }

  /// Apple Sign-In
  static Future<User> signInWithApple() async {
    try {
      // Apple Sign-In フロー
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Firebase認証情報を作成
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Firebaseにサインイン
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        throw Exception('認証に失敗しました');
      }

      return userCredential.user!;
    } catch (e) {
      rethrow;
    }
  }

  /// デモアカウント認証（デバッグ時のみ）
  static Future<User> signInWithDemo() async {
    if (!kDebugMode) {
      throw Exception('デモアカウントはデバッグモードでのみ使用できます');
    }

    try {
      // デモ用の固定メールアドレスとパスワード
      const email = 'demo@nursing-exam-app.local';
      const password = 'demo_password_2024';

      UserCredential userCredential;

      // アカウントが存在しない場合は作成
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // デバッグ用: エラーコードと詳細を出力
        if (kDebugMode) {
          print('FirebaseAuthException: ${e.code}');
          print('Message: ${e.message}');
        }

        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // ユーザーが存在しない場合は新規作成
          try {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } on FirebaseAuthException catch (createError) {
            if (kDebugMode) {
              print('Create account error: ${createError.code}');
              print('Message: ${createError.message}');
            }
            throw Exception('デモアカウントの作成に失敗しました: ${createError.message}');
          }
        } else {
          throw Exception('認証エラー (${e.code}): ${e.message}');
        }
      }

      if (userCredential.user == null) {
        throw Exception('デモアカウント認証に失敗しました');
      }

      return userCredential.user!;
    } catch (e) {
      rethrow;
    }
  }

  /// サインアウト
  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
