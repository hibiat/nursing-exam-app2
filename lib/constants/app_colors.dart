import 'package:flutter/material.dart';

/// アプリ全体で使用する色定義
/// 医療系の信頼感 + 学生向けの親しみやすさを両立
class AppColors {
  // プライマリカラー: 深めのブルー(信頼感)
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryContainer = Color(0xFFBBDEFB);
  
  // アクセントカラー
  static const Color success = Color(0xFF4CAF50); // 緑: 成功・正解
  static const Color warning = Color(0xFFFFC107); // 黄色: 注意
  static const Color scoreUp = Color(0xFFFF9800); // オレンジ: スコア上昇
  static const Color scoreDown = Color(0xFF607D8B); // ブルーグレー: スコア下降
  
  // 背景・サーフェス
  static const Color background = Color(0xFFF5F5F5); // オフホワイト
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEEEEEE);
  
  // 合格予測用の色
  static const Color passingSafe = Color(0xFF4CAF50); // 合格圏内
  static const Color passingBorder = Color(0xFFFF9800); // ボーダーライン
  static const Color passingRisk = Color(0xFF2196F3); // 未到達(赤は避ける)
  
  // テキストカラー
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
}
