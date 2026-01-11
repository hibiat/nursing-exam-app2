import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attempt.dart';

class AttemptRepository {
  AttemptRepository(this.firestore, this.uid);

  final FirebaseFirestore firestore;
  final String uid;

  /// Firestore structure:
  /// users/{uid}/attempts/{attemptId}
  Future<void> saveAttempt(Attempt attempt) async {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('attempts')
        .doc(attempt.id)
        .set(attempt.toFirestore());
  }
}
