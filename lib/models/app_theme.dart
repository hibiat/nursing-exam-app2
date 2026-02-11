import 'package:flutter/material.dart';

enum AppTheme {
  cute('可愛い', Color(0xFFE91E63)),
  cool('クール', Color(0xFF2196F3)),
  neutral('ナチュラル', Color(0xFF795548)),
  warm('あたたかい', Color(0xFFFF9800)),
  dark('ダーク', Color(0xFF263238));

  const AppTheme(this.displayName, this.primaryColor);

  final String displayName;
  final Color primaryColor;

  static AppTheme fromStorage(String? raw) {
    return AppTheme.values.firstWhere(
      (theme) => theme.name == raw,
      orElse: () => AppTheme.cool,
    );
  }
}
