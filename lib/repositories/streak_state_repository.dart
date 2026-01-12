import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/streak_state.dart';

class StreakStateRepository {
  StreakStateRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Firestore structure:
  /// users/{uid}/streak_state/main
  Future<StreakState?> fetchStreakState() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('streak_state')
        .doc('main')
        .get();
    if (!doc.exists) return null;
    return StreakState.fromFirestore(doc.data() ?? {});
  }

  Future<void> saveStreakState(StreakState state) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('streak_state')
        .doc('main')
        .set(state.toFirestore(), SetOptions(merge: true));
  }
}
