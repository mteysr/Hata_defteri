import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../lessons/data/models/lesson.dart';
import '../../../mistakes/domain/models/mistake.dart';
import '../../../mistakes/domain/models/review_attempt.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../lessons/presentation/controllers/lesson_controller.dart';
import '../../../mistakes/presentation/controllers/mistake_controller.dart';

class SettingsState {
  final bool notificationsEnabled;
  final int notificationHour;
  final int notificationMinute;
  final int streakCount;

  SettingsState({
    required this.notificationsEnabled,
    required this.notificationHour,
    required this.notificationMinute,
    required this.streakCount,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
    int? streakCount,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      streakCount: streakCount ?? this.streakCount,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;
  final Box _settingsBox;

  SettingsNotifier(this._ref)
      : _settingsBox = Hive.box(AppConstants.settingsBoxName),
        super(SettingsState(
          notificationsEnabled: true,
          notificationHour: 9,
          notificationMinute: 0,
          streakCount: 0,
        )) {
    _loadSettings();
  }

  void _loadSettings() {
    final enabled = _settingsBox.get(AppConstants.notificationsEnabledKey, defaultValue: true) as bool;
    final hour = _settingsBox.get(AppConstants.notificationHourKey, defaultValue: 9) as int;
    final minute = _settingsBox.get(AppConstants.notificationMinuteKey, defaultValue: 0) as int;
    
    // Streak check
    _checkStreakValidity();
    final streak = _settingsBox.get(AppConstants.streakCountKey, defaultValue: 0) as int;

    state = SettingsState(
      notificationsEnabled: enabled,
      notificationHour: hour,
      notificationMinute: minute,
      streakCount: streak,
    );
  }

  void _checkStreakValidity() {
    try {
      final lastActiveStr = _settingsBox.get(AppConstants.lastActiveDateKey) as String?;
      if (lastActiveStr != null) {
        final lastActive = DateTime.parse(lastActiveStr);
        final today = DateTime.now();
        final difference = DateTime(today.year, today.month, today.day)
            .difference(DateTime(lastActive.year, lastActive.month, lastActive.day))
            .inDays;

        if (difference > 1) {
          // Reset streak if inactive for more than 1 day
          _settingsBox.put(AppConstants.streakCountKey, 0);
        }
      }
    } catch (_) {}
  }

  Future<void> updateNotificationTime(int hour, int minute) async {
    await _settingsBox.put(AppConstants.notificationHourKey, hour);
    await _settingsBox.put(AppConstants.notificationMinuteKey, minute);
    state = state.copyWith(notificationHour: hour, notificationMinute: minute);
    _syncNotificationSchedule();
  }

  Future<void> toggleNotifications(bool enabled) async {
    await _settingsBox.put(AppConstants.notificationsEnabledKey, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
    _syncNotificationSchedule();
  }

  void _syncNotificationSchedule() {
    if (state.notificationsEnabled) {
      NotificationService.instance.scheduleDailyReviewNotification(
        hour: state.notificationHour,
        minute: state.notificationMinute,
      );
    } else {
      NotificationService.instance.cancelAllNotifications();
    }
  }

  Future<void> resetAllData() async {
    // Clear Database
    await DatabaseService.instance.clearAllData();
    // Reset App State via Providers
    _ref.read(themeModeProvider.notifier).loadTheme();
    _ref.read(lessonListProvider.notifier).loadLessons();
    _ref.read(mistakeListProvider.notifier).loadMistakes();
    _loadSettings();
    _syncNotificationSchedule();
  }

  // Backup Export
  Future<void> exportBackup() async {
    try {
      final lessons = Hive.box<Lesson>(AppConstants.lessonsBoxName).values.toList();
      final mistakes = Hive.box<Mistake>(AppConstants.mistakesBoxName).values.toList();

      final exportData = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'lessons': lessons.map((l) => {
          'id': l.id,
          'name': l.name,
          'colorValue': l.colorValue,
          'iconCodePoint': l.iconCodePoint,
          'subjects': l.subjects,
        }).toList(),
        'mistakes': mistakes.map((m) => {
          'id': m.id,
          'lessonId': m.lessonId,
          'subject': m.subject,
          'sourceBook': m.sourceBook,
          'mockExamName': m.mockExamName,
          'testName': m.testName,
          'pageNumber': m.pageNumber,
          'questionNumber': m.questionNumber,
          'difficulty': m.difficulty,
          'reason': m.reason,
          'note': m.note,
          'tags': m.tags,
          'questionImagePath': m.questionImagePath,
          'solutionImagePath': m.solutionImagePath,
          'createdAt': m.createdAt.toIso8601String(),
          'nextReviewAt': m.nextReviewAt.toIso8601String(),
          'reviewStage': m.reviewStage,
          'isCompleted': m.isCompleted,
          'reviewAttempts': m.reviewAttempts.map((a) => {
            'attemptedAt': a.attemptedAt.toIso8601String(),
            'isCorrect': a.isCorrect,
            'stageBefore': a.stageBefore,
            'stageAfter': a.stageAfter,
          }).toList(),
        }).toList(),
      };

      final jsonString = jsonEncode(exportData);
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/hata_defteri_yedek.json');
      await backupFile.writeAsString(jsonString);

      // Trigger standard system share sheet
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Hata Defteri Yedek Dosyası',
      );
    } catch (e) {
      print('Backup Export Error: $e');
    }
  }

  // Backup Import
  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data['version'] != 1) {
        return false;
      }

      final lessonsBox = Hive.box<Lesson>(AppConstants.lessonsBoxName);
      final mistakesBox = Hive.box<Mistake>(AppConstants.mistakesBoxName);

      // Clear existing data boxes
      await lessonsBox.clear();
      await mistakesBox.clear();

      // Restore Lessons
      final List<dynamic> importedLessons = data['lessons'] ?? [];
      for (var l in importedLessons) {
        final lesson = Lesson(
          id: l['id'],
          name: l['name'],
          colorValue: l['colorValue'],
          iconCodePoint: l['iconCodePoint'],
          subjects: List<String>.from(l['subjects'] ?? []),
        );
        await lessonsBox.put(lesson.id, lesson);
      }

      // Restore Mistakes
      final List<dynamic> importedMistakes = data['mistakes'] ?? [];
      for (var m in importedMistakes) {
        final List<dynamic> attemptsData = m['reviewAttempts'] ?? [];
        final attempts = attemptsData.map((a) => ReviewAttempt(
          attemptedAt: DateTime.parse(a['attemptedAt']),
          isCorrect: a['isCorrect'],
          stageBefore: a['stageBefore'],
          stageAfter: a['stageAfter'],
        )).toList();

        final mistake = Mistake(
          id: m['id'],
          lessonId: m['lessonId'],
          subject: m['subject'],
          sourceBook: m['sourceBook'],
          mockExamName: m['mockExamName'],
          testName: m['testName'],
          pageNumber: m['pageNumber'],
          questionNumber: m['questionNumber'],
          difficulty: m['difficulty'],
          reason: m['reason'],
          note: m['note'],
          tags: List<String>.from(m['tags'] ?? []),
          questionImagePath: m['questionImagePath'],
          solutionImagePath: m['solutionImagePath'],
          createdAt: DateTime.parse(m['createdAt']),
          nextReviewAt: DateTime.parse(m['nextReviewAt']),
          reviewStage: m['reviewStage'],
          isCompleted: m['isCompleted'] ?? false,
          reviewAttempts: attempts,
        );
        await mistakesBox.put(mistake.id, mistake);
      }

      // Refresh Providers
      _ref.read(lessonListProvider.notifier).loadLessons();
      _ref.read(mistakeListProvider.notifier).loadMistakes();
      _loadSettings();
      _syncNotificationSchedule();

      return true;
    } catch (e) {
      print('Backup Import Error: $e');
      return false;
    }
  }
}
