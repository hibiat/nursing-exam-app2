import 'dart:math';

/// 共感的なメッセージ集
class EncouragementMessages {
  static final Random _random = Random();

  // スコア上昇時
  static final List<String> scoreUp = [
    'この調子! {domain}領域が伸びてきたね 👏',
    'すごい! 着実に成長してるよ 🌟',
    '順調だね! この調子で頑張ろう 💪',
    'よくやった! {domain}の理解が深まってきたね ✨',
    '素晴らしい! 努力が実を結んでるよ 🎉',
  ];

  // スコア下降時
  static final List<String> scoreDown = [
    '大丈夫、次は取り戻せるよ 💪',
    '一時的な下降だから気にしないで 😊',
    '焦らず、自分のペースで進もう 🌈',
    'こういう日もあるよ。明日また頑張ろう ☀️',
    '下がった分は必ず取り返せるから安心して 💙',
  ];

  // スコア変化なし
  static final List<String> scoreStable = [
    '着実に力をつけてるよ! 🎯',
    '安定してるね。この調子! 👍',
    '基礎がしっかり固まってきてるよ ✨',
    '順調に進んでるね! 😊',
    '堅実に学習できてるよ 💯',
  ];

  // 学習開始時
  static final List<String> studyStart = [
    '今日もお疲れさま! 一緒に頑張ろう 😊',
    'さあ、今日も一歩ずつ進もう 🚀',
    '今日の学習、応援してるよ! 💪',
    'いつもよく頑張ってるね! 今日もファイト ✨',
    '一緒に成長していこう! 🌱',
  ];

  // 目標達成時
  static final List<String> goalComplete = [
    '今日の目標クリア! よくやった 🌟',
    '素晴らしい! 目標達成だね 🎉',
    'やったね! 今日もよく頑張った 👏',
    '完璧! 毎日の積み重ねが大事だよ 💯',
    '目標達成! この調子で続けよう 🚀',
  ];

  // 連続ログイン時
  static String consecutiveDays(int days) {
    if (days >= 7) {
      return '$days日連続ログイン! すごい継続力 🔥';
    } else if (days >= 3) {
      return '$days日連続! この調子で続けよう ✨';
    } else {
      return '$days日連続! 習慣になってきたね 😊';
    }
  }

  // 週間の学習量
  static String weeklyQuestions(int count) {
    if (count >= 100) {
      return '今週は${count}問も解いたね! 素晴らしい 🎉';
    } else if (count >= 50) {
      return '今週は${count}問解いたよ! よく頑張った 👏';
    } else if (count > 0) {
      return '今週は${count}問解いたね! 継続が大事 💪';
    } else {
      return '今週も一緒に頑張ろう! 😊';
    }
  }

  // ランダムに1つ取得
  static String randomScoreUp({String domain = ''}) {
    final message = scoreUp[_random.nextInt(scoreUp.length)];
    return message.replaceAll('{domain}', domain);
  }

  static String randomScoreDown() {
    return scoreDown[_random.nextInt(scoreDown.length)];
  }

  static String randomScoreStable() {
    return scoreStable[_random.nextInt(scoreStable.length)];
  }

  static String randomStudyStart() {
    return studyStart[_random.nextInt(studyStart.length)];
  }

  static String randomGoalComplete() {
    return goalComplete[_random.nextInt(goalComplete.length)];
  }
}
