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
      final score = scoreFromTheta(theta);
      return ScoreResult(theta: theta, score: score, rank: rankFromScore(score));
    }

    final result = isCorrect ? 1.0 : 0.0;
    // TODO: Replace difficulty with inferred item parameters once Cloud Functions aggregates stats.
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
    final score = scoreFromTheta(updatedTheta);

    return ScoreResult(
      theta: updatedTheta,
      score: score,
      rank: rankFromScore(score),
    );
  }

  double scoreFromTheta(double theta) {
    return (50 + 20 * theta).clamp(0, 100).toDouble();
  }

  String rankFromScore(double score) {
    if (score >= 80) return 'S';
    if (score >= 60) return 'A';
    if (score >= 40) return 'B';
    if (score >= 20) return 'C';
    return 'D';
  }

  double _stateWeight({
    required bool isCorrect,
    required bool wasIncorrectBefore,
    required bool wasMostlyCorrect,
  }) {
    if (isCorrect && wasIncorrectBefore) {
      return 1.8;
    }
    if (isCorrect && wasMostlyCorrect) {
      return 0.6;
    }
    return 1.0;
  }

  double _confidenceWeight(String? confidence, {required bool isSkip}) {
    if (isSkip) return 1.0;
    if (confidence == null) return 1.0;
    return confidence == 'low' ? 0.9 : 1.0;
  }
}
