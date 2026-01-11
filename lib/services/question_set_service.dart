import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/question.dart';

class QuestionSetService {
  QuestionSetService({FirebaseStorage? storage, FirebaseFirestore? firestore})
      : _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Future<List<Question>> loadQuestionsFromStorage(String path) async {
    final ref = _storage.ref(path);
    final data = await ref.getData();
    if (data == null) return [];

    final lines = const LineSplitter().convert(utf8.decode(data));
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => Question.fromJson(jsonDecode(line) as Map<String, dynamic>))
        .toList();
  }

  Future<String?> loadActiveSetId() async {
    final snapshot = await _firestore
        .collection('question_sets')
        .where('active', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }

  Future<List<Question>> loadActiveQuestions({required String mode}) async {
    final setId = await loadActiveSetId();
    if (setId == null) return [];
    final path = mode == 'required'
        ? 'question_sets/$setId/questions_required.jsonl'
        : 'question_sets/$setId/questions_general.jsonl';
    return loadQuestionsFromStorage(path);
  }
}
