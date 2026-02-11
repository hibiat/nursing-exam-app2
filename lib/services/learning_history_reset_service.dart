import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 学習履歴をFirebase上から削除して、初回起動相当の状態へ戻す。
class LearningHistoryResetService {
  LearningHistoryResetService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> resetAllLearningHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    await _deleteCollection(userRef.collection('attempts'));
    await _deleteCollection(userRef.collection('question_state'));
    await _deleteCollection(userRef.collection('skill_state'));
    await _deleteCollection(userRef.collection('streak_state'));
    await _deleteCollection(userRef.collection('profile'));
  }

  Future<void> _deleteCollection(CollectionReference<Map<String, dynamic>> collection) async {
    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
