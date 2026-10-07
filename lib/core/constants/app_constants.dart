import 'package:flutter/material.dart';

class AppConstants {
  // Hive Boxes
  static const String lessonsBoxName = 'lessons_box';
  static const String mistakesBoxName = 'mistakes_box';
  static const String settingsBoxName = 'settings_box';

  // Settings Keys
  static const String themeModeKey = 'theme_mode';
  static const String notificationHourKey = 'notification_hour';
  static const String notificationMinuteKey = 'notification_minute';
  static const String notificationsEnabledKey = 'notifications_enabled';
  
  // Streak Keys
  static const String streakCountKey = 'streak_count';
  static const String lastActiveDateKey = 'last_active_date';

  // Spaced Repetition Intervals (in days)
  static const List<int> reviewIntervals = [1, 3, 7, 15, 30];

  // Difficulty translations and keys
  static const Map<String, String> difficultyTranslations = {
    'EASY': 'Kolay',
    'MEDIUM': 'Orta',
    'HARD': 'Zor',
  };

  // Mistake reasons translations
  static const Map<String, String> reasonTranslations = {
    'CARELESSNESS': 'Dikkat Hatası',
    'LACK_OF_KNOWLEDGE': 'Bilgi Eksikliği',
    'CALCULATION_ERROR': 'İşlem Hatası',
    'MISREADING': 'Yanlış Okuma',
    'OUT_OF_TIME': 'Süre Yetmedi',
    'OTHER': 'Diğer',
  };

  // Helper to map dynamic/saved codepoints to constant IconData
  // to avoid tree-shaking failures during release builds
  static IconData getIconData(int codePoint) {
    if (codePoint == Icons.menu_book.codePoint) return Icons.menu_book;
    if (codePoint == Icons.functions.codePoint) return Icons.functions;
    if (codePoint == Icons.translate.codePoint) return Icons.translate;
    if (codePoint == Icons.history.codePoint) return Icons.history;
    if (codePoint == Icons.public.codePoint) return Icons.public;
    if (codePoint == Icons.gavel.codePoint) return Icons.gavel;
    if (codePoint == Icons.category.codePoint) return Icons.category;
    if (codePoint == Icons.science.codePoint) return Icons.science;
    if (codePoint == Icons.opacity.codePoint) return Icons.opacity;
    if (codePoint == Icons.spa.codePoint) return Icons.spa;
    if (codePoint == Icons.language.codePoint) return Icons.language;
    return Icons.menu_book; // Fallback constant icon
  }
}
