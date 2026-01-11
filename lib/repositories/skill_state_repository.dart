import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/skill_state.dart';

class SkillStateRepository {
  SkillStateRepository(this.firestore, this.uid);

  final FirebaseFirestore firestore;
  final String uid;

  /// Firestore structure:
  /// users/{uid}/skill_state/{subdomainId}
  Future<void> saveSkillState(SkillState state) async {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('skill_state')
        .doc(state.subdomainId)
        .set(state.toFirestore());
  }
}
