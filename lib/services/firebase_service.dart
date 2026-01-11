import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  FirebaseService._();

  static final instance = FirebaseService._();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  /// Firestore collections (read/write rules):
  /// - users/{uid}/attempts/{attemptId} (user read/write)
  /// - users/{uid}/question_state/{questionId} (user read/write)
  /// - users/{uid}/skill_state/{subdomainId} (user read/write)
  /// - question_sets/{setId} (read-only)
  /// - stats/{statId} (read-only, future difficulty aggregation)
  ///
  /// Storage paths (read-only):
  /// - question_sets/{setId}/questions_general.jsonl
  /// - question_sets/{setId}/questions_required.jsonl
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (error) {
      // Allow app boot without Firebase options (e.g. web preview).
    }
  }
}
