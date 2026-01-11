import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/question_state.dart';

class QuestionStateRepository {
  QuestionStateRepository(this.firestore, this.uid);

  final FirebaseFirestore firestore;
  final String uid;

  /// Firestore structure:
  /// users/{uid}/question_state/{questionId}
  Future<void> saveQuestionState(QuestionState state) async {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('question_state')
        .doc(state.questionId)
        .set(state.toFirestore());
  }
}
