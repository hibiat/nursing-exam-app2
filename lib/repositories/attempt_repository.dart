import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/attempt.dart';

class AttemptRepository {
  AttemptRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Firestore structure:
  /// users/{uid}/attempts/{autoId}
  Future<void> saveAttempt(Attempt attempt) async {
    final user = _auth.currentUser;
    if (user == null) return;
    // TODO: Aggregate attempt stats via Cloud Functions for difficulty calibration.
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('attempts')
        .add(attempt.toFirestore());
  }

  /// 指定期間のAttemptを取得
  Future<List<Attempt>> fetchAttemptsByDateRange(
    DateTime start,
    DateTime end, {
    int? limit,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    var query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('attempts')
        .where('answeredAt', isGreaterThanOrEqualTo: start)
        .where('answeredAt', isLessThan: end)
        .orderBy('answeredAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => Attempt.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
