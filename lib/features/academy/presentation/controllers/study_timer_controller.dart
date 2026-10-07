import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class StudyTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final String mode; // 'pomodoro', 'shortBreak', 'longBreak'
  final String category; // 'Tarih', 'Coğrafya', 'Vatandaşlık'
  final String topic;

  StudyTimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.mode,
    required this.category,
    required this.topic,
  });

  StudyTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    String? mode,
    String? category,
    String? topic,
  }) {
    return StudyTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      mode: mode ?? this.mode,
      category: category ?? this.category,
      topic: topic ?? this.topic,
    );
  }
}

final studyTimerProvider = StateNotifierProvider<StudyTimerNotifier, StudyTimerState>((ref) {
  return StudyTimerNotifier();
});

class StudyTimerNotifier extends StateNotifier<StudyTimerState> {
  Timer? _timer;

  StudyTimerNotifier()
      : super(StudyTimerState(
          remainingSeconds: 25 * 60,
          totalSeconds: 25 * 60,
          isRunning: false,
          mode: 'pomodoro',
          category: 'Tarih',
          topic: 'Genel Tekrar',
        ));

  void setMode(String mode) {
    _timer?.cancel();
    int seconds = 25 * 60;
    if (mode == 'shortBreak') seconds = 5 * 60;
    if (mode == 'longBreak') seconds = 15 * 60;

    state = state.copyWith(
      isRunning: false,
      mode: mode,
      remainingSeconds: seconds,
      totalSeconds: seconds,
    );
  }

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setTopic(String topic) {
    state = state.copyWith(topic: topic.isEmpty ? 'Genel Tekrar' : topic);
  }

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _onTimerComplete();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    int seconds = 25 * 60;
    if (state.mode == 'shortBreak') seconds = 5 * 60;
    if (state.mode == 'longBreak') seconds = 15 * 60;

    state = state.copyWith(
      isRunning: false,
      remainingSeconds: seconds,
    );
  }

  Future<void> _onTimerComplete() async {
    pause();
    
    if (state.mode == 'pomodoro') {
      final int completedMinutes = (state.totalSeconds - state.remainingSeconds) ~/ 60;
      if (completedMinutes > 0) {
        await logStudySession(
          category: state.category,
          topic: state.topic,
          durationMinutes: completedMinutes,
        );
      }
    }

    // Reset countdown based on mode
    reset();
  }

  // Exposed helper to log custom study sessions manually or force log sessions
  Future<void> logStudySession({
    required String category,
    required String topic,
    required int durationMinutes,
  }) async {
    try {
      final box = Hive.box('academy_settings_box');
      final rawList = box.get('study_sessions', defaultValue: []);
      final List<Map<String, dynamic>> list = List<dynamic>.from(rawList)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final newLog = {
        'id': const Uuid().v4(),
        'category': category,
        'topic': topic,
        'durationMinutes': durationMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      };

      list.add(newLog);
      await box.put('study_sessions', list);
    } catch (e) {
      debugPrint('Error logging study session: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
