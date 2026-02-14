import 'package:flutter/material.dart';

enum AppTheme {
  light('キュート', Color(0xFFE26AA5)),
  neutral('ナチュラル', Color(0xFF795548)),
  dark('ダーク', Color(0xFF263238));

  const AppTheme(this.displayName, this.primaryColor);

  final String displayName;
  final Color primaryColor;

  static AppTheme fromStorage(String? raw) {
    if (raw == 'cute' || raw == 'cool' || raw == 'warm') {
      return AppTheme.light;
    }
    return AppTheme.values.firstWhere(
      (theme) => theme.name == raw,
      orElse: () => AppTheme.light,
    );
  }
}
