import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';

import '../models/question.dart';

class QuestionSetService {
  QuestionSetService(this.storage);

  final FirebaseStorage storage;

  Future<List<Question>> loadQuestionsFromStorage(String path) async {
    final ref = storage.ref(path);
    final data = await ref.getData();
    if (data == null) return [];

    final lines = const LineSplitter().convert(utf8.decode(data));
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => Question.fromJson(jsonDecode(line) as Map<String, dynamic>))
        .toList();
  }
}
