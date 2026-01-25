import 'dart:math';

class ScoreResult {
  const ScoreResult({
    required this.theta,
    required this.score,
    required this.rank,
  });

  final double theta;
  final double score;
  final String rank;
}

class ScoreEngine {
  ScoreEngine({this.learningRate = 0.12});

  final double learningRate;

  ScoreResult updateTheta({
    required double theta,
    required bool isCorrect,
    required bool isSkip,
    required bool timeExpired,
    required bool wasIncorrectBefore,
    required bool wasMostlyCorrect,
    required String? confidence,
    required double difficulty,
  }) {
    if (timeExpired) {
      return ScoreResult(theta: theta, score: 0, rank: 'D');
    }

    final result = isCorrect ? 1.0 : 0.0;
    final beta = (difficulty - 0.5) * 2.0;
    final p = 1 / (1 + exp(-(theta - beta)));

    final wState = _stateWeight(
      isCorrect: isCorrect,
      wasIncorrectBefore: wasIncorrectBefore,
      wasMostlyCorrect: wasMostlyCorrect,
    );
    final wConf = _confidenceWeight(confidence, isSkip: isSkip);
    final wDiff = 0.7 + 0.6 * difficulty;

    final updatedTheta = theta + learningRate * wState * wConf * wDiff * (result - p);

    return ScoreResult(
      theta: updatedTheta,
      score: 0, // 使用しない
      rank: 'B', // 使用しない
    );
  }

  /// thetaから必修問題のスコアに変換(50点満点)
  /// theta=0 で 40点(合格ライン)
  double thetaToRequiredScore(double theta) {
    return (40 + theta * 5).clamp(0, 50).toDouble();
  }

  /// thetaから一般・状況設定問題のスコアに変換(250点満点)
  /// theta=0 で 162.5点(平均)
  double thetaToGeneralScore(double theta) {
    return (162.5 + theta * 37.5).clamp(0, 250).toDouble();
  }

  /// 必修スコアからランクを判定
  String requiredRankFromScore(double score) {
    if (score >= 48) return 'S';  // 96%+
    if (score >= 45) return 'A';  // 90%+
    if (score >= 40) return 'B';  // 80%+ (合格ライン)
    if (score >= 35) return 'C';  // 70%+
    return 'D';
  }

  /// 一般・状況設定スコアからランクを判定
  String generalRankFromScore(double score) {
    if (score >= 200) return 'S';  // 80%+
    if (score >= 175) return 'A';  // 70%+
    if (score >= 150) return 'B';  // 60%+ (合格ライン)
    if (score >= 125) return 'C';  // 50%+
    return 'D';
  }

  /// 合格確率を計算
  double calculatePassingProbability({
    required double requiredScore,
    required double generalScore,
  }) {
    final requiredPass = requiredScore >= 40;
    final generalPass = generalScore >= 150;

    if (!requiredPass || !generalPass) {
      if (requiredScore >= 35 && generalScore >= 125) {
        return 0.5;
      }
      return 0.3;
    }

    final requiredMargin = ((requiredScore - 40) / 10).clamp(0, 1);
    final generalMargin = ((generalScore - 150) / 50).clamp(0, 1);
    final avgMargin = (requiredMargin + generalMargin) / 2;
    
    return (0.75 + avgMargin * 0.23).clamp(0.3, 0.98);
  }

  double _stateWeight({
    required bool isCorrect,
    required bool wasIncorrectBefore,
    required bool wasMostlyCorrect,
  }) {
    if (isCorrect && wasIncorrectBefore) return 1.8;
    if (isCorrect && wasMostlyCorrect) return 0.6;
    return 1.0;
  }

  double _confidenceWeight(String? confidence, {required bool isSkip}) {
    if (isSkip) return 1.0;
    if (confidence == null) return 1.0;
    return confidence == 'low' ? 0.9 : 1.0;
  }
}