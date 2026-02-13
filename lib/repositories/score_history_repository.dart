import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/score_history_point.dart';

class ScoreHistoryRepository {
  ScoreHistoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Firestore structure:
  /// users/{uid}/score_history/{date}
  ///
  /// スコアスナップショットを保存
  /// 日付形式: yyyy-MM-dd
  Future<void> saveScoreSnapshot({
    required String date,
    required double requiredScore,
    required double generalScore,
    required String requiredRank,
    required String generalRank,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    // 必修スコアを保存
    final requiredRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('score_history')
        .doc('$date-required');

    batch.set(requiredRef, {
      'date': date,
      'score': requiredScore,
      'rank': requiredRank,
      'mode': 'required',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 一般・状況設定スコアを保存
    final generalRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('score_history')
        .doc('$date-general');

    batch.set(generalRef, {
      'date': date,
      'score': generalScore,
      'rank': generalRank,
      'mode': 'general',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// 指定期間のスコア履歴を取得
  Future<List<ScoreHistoryPoint>> fetchScoreHistory({
    required String mode,
    required DateTime start,
    required DateTime end,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('score_history')
        .where('mode', isEqualTo: mode)
        .where('date', isGreaterThanOrEqualTo: _formatDate(start))
        .where('date', isLessThan: _formatDate(end))
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ScoreHistoryPoint.fromFirestore(doc.data()))
        .toList();
  }

  /// 最新のスコアポイントを取得
  Future<ScoreHistoryPoint?> fetchLatestScore({required String mode}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('score_history')
        .where('mode', isEqualTo: mode)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return ScoreHistoryPoint.fromFirestore(snapshot.docs.first.data());
  }

  /// 日付を yyyy-MM-dd 形式にフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
