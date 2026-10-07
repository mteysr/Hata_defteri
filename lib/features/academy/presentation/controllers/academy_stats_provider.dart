import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../domain/models/academy_answer_history.dart';

class AcademyStats {
  final int totalQuestions;
  final int totalCorrect;
  final int totalIncorrect;
  
  final double historySuccessRate;
  final double geographySuccessRate;
  final double civicsSuccessRate;

  final String weakestTopic;
  final String strongestTopic;

  final List<DailyAcademyProgress> last30DaysProgress;

  AcademyStats({
    required this.totalQuestions,
    required this.totalCorrect,
    required this.totalIncorrect,
    required this.historySuccessRate,
    required this.geographySuccessRate,
    required this.civicsSuccessRate,
    required this.weakestTopic,
    required this.strongestTopic,
    required this.last30DaysProgress,
  });

  double get overallSuccessRate {
    if (totalQuestions == 0) return 0.0;
    return (totalCorrect / totalQuestions) * 100;
  }
}

class DailyAcademyProgress {
  final DateTime date;
  final int totalCount;
  final int correctCount;

  DailyAcademyProgress({
    required this.date,
    required this.totalCount,
    required this.correctCount,
  });
}

final academyStatsProvider = Provider<AcademyStats>((ref) {
  final historyBox = Hive.box<AcademyAnswerHistory>('academy_history_box');
  final logs = historyBox.values.toList();

  int totalQuestions = logs.length;
  int totalCorrect = logs.where((l) => l.isCorrect).length;
  int totalIncorrect = totalQuestions - totalCorrect;

  // Category counts
  int historyTotal = 0;
  int historyCorrect = 0;
  int geographyTotal = 0;
  int geographyCorrect = 0;
  int civicsTotal = 0;
  int civicsCorrect = 0;

  // Topic metrics
  final Map<String, List<bool>> topicAttempts = {};

  for (final log in logs) {
    if (log.category == 'Tarih') {
      historyTotal++;
      if (log.isCorrect) historyCorrect++;
    } else if (log.category == 'Coğrafya') {
      geographyTotal++;
      if (log.isCorrect) geographyCorrect++;
    } else if (log.category == 'Vatandaşlık') {
      civicsTotal++;
      if (log.isCorrect) civicsCorrect++;
    }

    // Track topic success
    final topicKey = '${log.category} - ${log.topic}';
    if (!topicAttempts.containsKey(topicKey)) {
      topicAttempts[topicKey] = [];
    }
    topicAttempts[topicKey]!.add(log.isCorrect);
  }

  double historySuccessRate = historyTotal > 0 ? (historyCorrect / historyTotal) * 100 : 0.0;
  double geographySuccessRate = geographyTotal > 0 ? (geographyCorrect / geographyTotal) * 100 : 0.0;
  double civicsSuccessRate = civicsTotal > 0 ? (civicsCorrect / civicsTotal) * 100 : 0.0;

  // Calculate weakest and strongest topics
  String weakestTopic = '-';
  String strongestTopic = '-';
  
  if (topicAttempts.isNotEmpty) {
    double minRate = 101.0;
    double maxRate = -1.0;

    for (var entry in topicAttempts.entries) {
      final topic = entry.key;
      final attempts = entry.value;
      final correctCount = attempts.where((a) => a).length;
      final rate = (correctCount / attempts.length) * 100;

      // Weakest Topic (with lowest success rate)
      if (rate < minRate) {
        minRate = rate;
        weakestTopic = '$topic (%${rate.toStringAsFixed(0)})';
      }

      // Strongest Topic (with highest success rate)
      if (rate > maxRate) {
        maxRate = rate;
        strongestTopic = '$topic (%${rate.toStringAsFixed(0)})';
      }
    }
  }

  // Calculate last 30 days progress
  final last30DaysProgress = <DailyAcademyProgress>[];
  final today = DateUtils.dateOnly(DateTime.now());

  for (int i = 29; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final dayLogs = logs.where((l) => DateUtils.dateOnly(l.answeredAt).isAtSameMomentAs(date));

    final totalCount = dayLogs.length;
    final correctCount = dayLogs.where((l) => l.isCorrect).length;

    last30DaysProgress.add(DailyAcademyProgress(
      date: date,
      totalCount: totalCount,
      correctCount: correctCount,
    ));
  }

  return AcademyStats(
    totalQuestions: totalQuestions,
    totalCorrect: totalCorrect,
    totalIncorrect: totalIncorrect,
    historySuccessRate: historySuccessRate,
    geographySuccessRate: geographySuccessRate,
    civicsSuccessRate: civicsSuccessRate,
    weakestTopic: weakestTopic,
    strongestTopic: strongestTopic,
    last30DaysProgress: last30DaysProgress,
  );
});
