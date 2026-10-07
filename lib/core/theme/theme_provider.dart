import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    loadTheme();
  }

  void loadTheme() {
    try {
      final box = Hive.box(AppConstants.settingsBoxName);
      final isDark = box.get(AppConstants.themeModeKey);
      if (isDark == null) {
        state = ThemeMode.system;
      } else {
        state = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final box = Hive.box(AppConstants.settingsBoxName);
      box.put(AppConstants.themeModeKey, isDark);
    } catch (_) {}
  }
}
