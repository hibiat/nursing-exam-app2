import 'package:cloud_firestore/cloud_firestore.dart';

/// スコア推移グラフのデータポイント
class ScoreHistoryPoint {
  const ScoreHistoryPoint({
    required this.date,
    required this.score,
    required this.rank,
    required this.mode,
  });

  final DateTime date;
  final double score;
  final String rank; // 'S', 'A', 'B', 'C', 'D'
  final String mode; // 'required' or 'general'

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'score': score,
      'rank': rank,
      'mode': mode,
    };
  }

  factory ScoreHistoryPoint.fromFirestore(Map<String, dynamic> data) {
    return ScoreHistoryPoint(
      date: (data['date'] as Timestamp).toDate(),
      score: (data['score'] as num).toDouble(),
      rank: data['rank'] as String,
      mode: data['mode'] as String,
    );
  }
}
