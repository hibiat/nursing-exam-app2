import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_theme.dart';
import '../repositories/user_settings_repository.dart';

class ThemeService extends ChangeNotifier {
  ThemeService({UserSettingsRepository? repository})
      : _repository = repository ?? UserSettingsRepository();

  final UserSettingsRepository _repository;
  AppTheme _currentTheme = AppTheme.light;

  AppTheme get currentTheme => _currentTheme;

  Future<void> loadFromSettings() async {
    final settings = await _repository.fetchSettings();
    _currentTheme = settings.theme;
    notifyListeners();
  }

  void changeTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  ThemeData get themeData => _buildTheme(_currentTheme);

  ThemeData _buildTheme(AppTheme theme) {
    final colorScheme = switch (theme) {
      AppTheme.light => ColorScheme.fromSeed(
          seedColor: const Color(0xFFE26AA5),
          brightness: Brightness.light,
        ),
      AppTheme.neutral => ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B7B6E),
          brightness: Brightness.light,
        ),
      AppTheme.dark => ColorScheme.fromSeed(
          seedColor: const Color(0xFF263238),
          brightness: Brightness.dark,
        ),
    };

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: GoogleFonts.notoSansJp().fontFamily,
      textTheme: GoogleFonts.notoSansJpTextTheme(),
      fontFamilyFallback: const ['Hiragino Sans', 'Yu Gothic', 'Meiryo', 'sans-serif'],
    );
  }
}
