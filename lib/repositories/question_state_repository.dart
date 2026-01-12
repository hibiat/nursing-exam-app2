import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/question_state.dart';

class QuestionStateRepository {
  QuestionStateRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Firestore structure:
  /// users/{uid}/question_state/{questionId}
  Future<void> saveQuestionState(QuestionState state) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('question_state')
        .doc(state.questionId)
        .set(state.toFirestore());
  }

  Future<List<QuestionState>> fetchQuestionStates({
    required String mode,
    required String domainId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('question_state')
        .where('mode', isEqualTo: mode)
        .where('domainId', isEqualTo: domainId)
        .get();
    return snapshot.docs
        .map((doc) => QuestionState.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<Map<String, int>> fetchDueCountsByDomain({required String mode}) async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('question_state')
        .where('mode', isEqualTo: mode)
        .get();
    final counts = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final domainId = (data['domainId'] as String?) ?? '';
      if (domainId.isEmpty) continue;
      final dueAt = data['dueAt'];
      if (dueAt is! Timestamp) continue;
      if (dueAt.toDate().isAfter(now)) continue;
      counts.update(domainId, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}
