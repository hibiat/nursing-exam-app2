import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_settings.dart';

class UserSettingsRepository {
  UserSettingsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // TODO: 国試の制限時間・問題数から適切な秒数を再計算し調整する。
  static const int defaultTimeLimitSeconds = 90;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Firestore structure:
  /// users/{uid}/settings/app
  Future<UserSettings> fetchSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const UserSettings(timeLimitSeconds: defaultTimeLimitSeconds);
    }
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('app')
        .get();
    return UserSettings.fromFirestore(doc.data() ?? {}, defaultTimeLimitSeconds);
  }

  Future<void> saveSettings(UserSettings settings) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('app')
        .set(settings.toFirestore(), SetOptions(merge: true));
  }
}
