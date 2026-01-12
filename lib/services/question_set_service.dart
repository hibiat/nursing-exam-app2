import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/question.dart';

class QuestionSetService {
  QuestionSetService({FirebaseStorage? storage, FirebaseFirestore? firestore})
      : _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Future<Uint8List?> _downloadBytes(Reference ref, String path) async {
    if (kIsWeb) {
      final url = await ref.getDownloadURL();
      // ignore: avoid_print
      print('QuestionSetService.download url=$url');
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception(
            'Storage download failed status=${response.statusCode} path=$path',
          );
        }
        return response.bodyBytes;
      } on http.ClientException catch (error) {
        throw Exception(
          'Storage download failed (web/CORS) path=$path error=$error. '
          'Check bucket CORS to allow localhost/web origin.',
        );
      }
    }
    return ref.getData();
  }

  Future<List<Question>> loadQuestionsFromStorage(String path) async {
    final ref = _storage.ref(path);
    // ignore: avoid_print
    print('QuestionSetService.loadQuestionsFromStorage path=$path');
    final data = await _downloadBytes(ref, path);
    if (data == null) return [];
    // ignore: avoid_print
    print('QuestionSetService.loadQuestionsFromStorage bytes=${data.length}');
    final lines = const LineSplitter().convert(utf8.decode(data));
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => Question.fromJson(jsonDecode(line) as Map<String, dynamic>))
        .toList();
  }

  Future<String?> loadActiveSetIdForMode(String mode) async {
    // ignore: avoid_print
    print('QuestionSetService.loadActiveSetIdForMode mode=$mode');
    final snapshot = await _firestore
        .collection('question_sets')
        .where('active', isEqualTo: true)
        .where('mode', isEqualTo: mode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // ignore: avoid_print
      print('QuestionSetService.loadActiveSetIdForMode none found');
      return null;
    }
    final setId = snapshot.docs.first.id;
    // ignore: avoid_print
    print('QuestionSetService.loadActiveSetIdForMode setId=$setId');
    return setId;
  }

  Future<List<Question>> loadActiveQuestions({required String mode}) async {
    final setId = await loadActiveSetIdForMode(mode);
    if (setId == null) return [];

    final path = mode == 'required'
        ? 'question_sets/$setId/questions_required.jsonl'
        : 'question_sets/$setId/questions_general.jsonl';

    return loadQuestionsFromStorage(path);
  }

}
