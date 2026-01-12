import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseService {
  FirebaseService._();

  static final instance = FirebaseService._();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Firestore collections (read/write rules):
  /// - users/{uid}/attempts/{attemptId} (user read/write)
  /// - users/{uid}/question_state/{questionId} (user read/write)
  /// - users/{uid}/skill_state/{skillId} (user read/write)
  /// - users/{uid}/profile/main (user read/write)
  /// - users/{uid}/settings/app (user read/write)
  /// - users/{uid}/streak_state/main (user read/write)
  /// - question_sets/{setId} (read-only)
  /// - stats/{statId} (read-only, future difficulty aggregation)
  ///
  /// Storage paths (read-only):
  /// - question_sets/{setId}/questions_general.jsonl
  /// - question_sets/{setId}/questions_required.jsonl
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (error) {
      // Allow app boot without Firebase options (e.g. web preview).
    }
  }
}
