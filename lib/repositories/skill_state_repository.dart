import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/skill_state.dart';

class SkillStateRepository {
  SkillStateRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Firestore structure:
  /// users/{uid}/skill_state/{subdomainId}
  Future<void> saveSkillState(SkillState state) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skill_state')
        .doc(state.subdomainId)
        .set(state.toFirestore());
  }
}
