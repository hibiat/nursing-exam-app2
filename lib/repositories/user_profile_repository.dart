import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Firestore structure:
  /// users/{uid}/profile/main
  Future<UserProfile?> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('main')
        .get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc.data() ?? {});
  }

  Future<void> saveProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('main')
        .set(profile.toFirestore(), SetOptions(merge: true));
  }
}
