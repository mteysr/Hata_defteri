import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../lessons/presentation/controllers/lesson_controller.dart';
import '../../../mistakes/presentation/controllers/mistake_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

class AppStatistics {
  final int totalMistakes;
  final int dueReviewCount;
  final int totalLessonsCount;
  final String mostWrongLesson;
  final Color mostWrongLessonColor;
  final String mostWrongSubject;
  final int currentStreak;
  final Map<DateTime, int> last7DaysMistakes; // Date -> Count
  final Map<String, int> lessonMistakesDistribution; // Lesson Name -> Count
  final Map<String, int> reasonMistakesDistribution; // Reason key -> Count
  final Map<String, int> subjectMistakesDistribution; // Subject Name -> Count
  final int totalSolvedReviews;
  final int correctReviewsCount;
  final double successRate;

  AppStatistics({
    required this.totalMistakes,
    required this.dueReviewCount,
    required this.totalLessonsCount,
    required this.mostWrongLesson,
    required this.mostWrongLessonColor,
    required this.mostWrongSubject,
    required this.currentStreak,
    required this.last7DaysMistakes,
    required this.lessonMistakesDistribution,
    required this.reasonMistakesDistribution,
    required this.subjectMistakesDistribution,
    required this.totalSolvedReviews,
    required this.correctReviewsCount,
    required this.successRate,
  });
}

final statisticsProvider = Provider<AppStatistics>((ref) {
  final mistakes = ref.watch(mistakeListProvider);
  final lessons = ref.watch(lessonListProvider);
  final settings = ref.watch(settingsProvider);

  // 1. Basic Stats
  final totalMistakes = mistakes.length;
  final totalLessonsCount = lessons.length;
  final currentStreak = settings.streakCount;

  // 2. Due for Review Today
  final today = DateUtils.dateOnly(DateTime.now());
  final dueReviewCount = mistakes.where((m) {
    if (m.isCompleted) return false;
    final nextReview = DateUtils.dateOnly(m.nextReviewAt);
    return nextReview.isBefore(today) || nextReview.isAtSameMomentAs(today);
  }).length;

  // 3. Lesson & Subject distributions
  final Map<String, int> lessonDistribution = {}; // Name -> Count
  final Map<String, int> subjectDistribution = {}; // Name -> Count
  final Map<String, int> reasonDistribution = {}; // Reason Key -> Count

  for (var mistake in mistakes) {
    // Lesson name resolution
    final lessonObj = lessons.firstWhere((l) => l.id == mistake.lessonId, orElse: () => lessons.first);
    final lessonName = lessonObj.name;
    lessonDistribution[lessonName] = (lessonDistribution[lessonName] ?? 0) + 1;

    // Subject
    final subject = mistake.subject;
    subjectDistribution[subject] = (subjectDistribution[subject] ?? 0) + 1;

    // Reason
    final reason = mistake.reason;
    reasonDistribution[reason] = (reasonDistribution[reason] ?? 0) + 1;
  }

  // 4. Most wrong lesson & subject
  String mostWrongLesson = 'Yok';
  Color mostWrongLessonColor = Colors.grey;
  if (lessonDistribution.isNotEmpty) {
    final sortedLessons = lessonDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    mostWrongLesson = sortedLessons.first.key;
    // Get color
    final match = lessons.firstWhere((l) => l.name == mostWrongLesson, orElse: () => lessons.first);
    mostWrongLessonColor = Color(match.colorValue);
  }

  String mostWrongSubject = 'Yok';
  if (subjectDistribution.isNotEmpty) {
    final sortedSubjects = subjectDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    mostWrongSubject = sortedSubjects.first.key;
  }

  // 5. Last 7 Days Mistake Log Chart
  final Map<DateTime, int> last7DaysMistakes = {};
  for (int i = 6; i >= 0; i--) {
    final day = DateUtils.dateOnly(DateTime.now().subtract(Duration(days: i)));
    last7DaysMistakes[day] = 0;
  }

  for (var mistake in mistakes) {
    final createdDay = DateUtils.dateOnly(mistake.createdAt);
    if (last7DaysMistakes.containsKey(createdDay)) {
      last7DaysMistakes[createdDay] = last7DaysMistakes[createdDay]! + 1;
    }
  }

  // 6. Review Stats
  int totalSolvedReviews = 0;
  int correctReviewsCount = 0;
  for (var mistake in mistakes) {
    for (var attempt in mistake.reviewAttempts) {
      totalSolvedReviews++;
      if (attempt.isCorrect) {
        correctReviewsCount++;
      }
    }
  }

  final double successRate = totalSolvedReviews > 0
      ? (correctReviewsCount / totalSolvedReviews) * 100
      : 0.0;

  return AppStatistics(
    totalMistakes: totalMistakes,
    dueReviewCount: dueReviewCount,
    totalLessonsCount: totalLessonsCount,
    mostWrongLesson: mostWrongLesson,
    mostWrongLessonColor: mostWrongLessonColor,
    mostWrongSubject: mostWrongSubject,
    currentStreak: currentStreak,
    last7DaysMistakes: last7DaysMistakes,
    lessonMistakesDistribution: lessonDistribution,
    reasonMistakesDistribution: reasonDistribution,
    subjectMistakesDistribution: subjectDistribution,
    totalSolvedReviews: totalSolvedReviews,
    correctReviewsCount: correctReviewsCount,
    successRate: successRate,
  );
});
