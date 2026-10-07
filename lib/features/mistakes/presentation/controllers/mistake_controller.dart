import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/models/mistake.dart';
import '../../domain/models/review_attempt.dart';
import '../../domain/repositories/mistake_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/constants/app_constants.dart';

// 1. Mistake List Notifier
final mistakeListProvider = StateNotifierProvider<MistakeListNotifier, List<Mistake>>((ref) {
  final repo = ref.watch(mistakeRepositoryProvider);
  return MistakeListNotifier(repo);
});

class MistakeListNotifier extends StateNotifier<List<Mistake>> {
  final MistakeRepository _repo;

  MistakeListNotifier(this._repo) : super([]) {
    loadMistakes();
  }

  void loadMistakes() {
    state = _repo.getMistakes();
  }

  Future<void> addMistake(Mistake mistake) async {
    await _repo.addMistake(mistake);
    loadMistakes();
  }

  Future<void> updateMistake(Mistake mistake) async {
    await _repo.updateMistake(mistake);
    loadMistakes();
  }

  Future<void> deleteMistake(String id) async {
    await _repo.deleteMistake(id);
    loadMistakes();
  }

  // Record a review session answer and recalculate schedule
  Future<void> recordReviewAttempt(String id, bool isCorrect) async {
    final mistake = state.firstWhere((m) => m.id == id);
    final now = DateTime.now();
    
    int stageBefore = mistake.reviewStage;
    int stageAfter = 0;
    DateTime nextReview;
    bool isCompleted = false;

    if (isCorrect) {
      stageAfter = stageBefore + 1;
      if (stageAfter >= AppConstants.reviewIntervals.length) {
        stageAfter = AppConstants.reviewIntervals.length; // Max stage
        isCompleted = true;
        // Effectively completed, check next year
        nextReview = now.add(const Duration(days: 3650));
      } else {
        final daysToAdd = AppConstants.reviewIntervals[stageAfter];
        nextReview = now.add(Duration(days: daysToAdd));
      }
    } else {
      // Failure resets back to the beginning
      stageAfter = 0;
      nextReview = now.add(const Duration(days: 1)); // 1 day
    }

    final newAttempt = ReviewAttempt(
      attemptedAt: now,
      isCorrect: isCorrect,
      stageBefore: stageBefore,
      stageAfter: stageAfter,
    );

    final updatedAttempts = List<ReviewAttempt>.from(mistake.reviewAttempts)..add(newAttempt);

    final updatedMistake = mistake.copyWith(
      reviewStage: stageAfter,
      isCompleted: isCompleted,
      nextReviewAt: nextReview,
      reviewAttempts: updatedAttempts,
    );

    await updateMistake(updatedMistake);
    
    // Update streak helper on successful attempts
    _updateStreak();
  }

  void _updateStreak() {
    try {
      final box = Hive.box(AppConstants.settingsBoxName);
      final todayStr = DateUtils.dateOnly(DateTime.now()).toIso8601String();
      final lastActiveStr = box.get(AppConstants.lastActiveDateKey) as String?;
      int currentStreak = box.get(AppConstants.streakCountKey, defaultValue: 0) as int;

      if (lastActiveStr == null) {
        box.put(AppConstants.streakCountKey, 1);
        box.put(AppConstants.lastActiveDateKey, todayStr);
      } else {
        final lastActiveDate = DateTime.parse(lastActiveStr);
        final today = DateUtils.dateOnly(DateTime.now());
        final diff = today.difference(lastActiveDate).inDays;

        if (diff == 1) {
          // yesterday was last active, increment
          currentStreak++;
          box.put(AppConstants.streakCountKey, currentStreak);
          box.put(AppConstants.lastActiveDateKey, todayStr);
        } else if (diff > 1) {
          // broken streak
          box.put(AppConstants.streakCountKey, 1);
          box.put(AppConstants.lastActiveDateKey, todayStr);
        }
        // if diff == 0 (already reviewed today), keep current streak
      }
    } catch (_) {}
  }
}

// 2. Mistake Filter State
class MistakeFilter {
  final String? lessonId;
  final String? subject;
  final String? difficulty;
  final String? reason;
  final String? tag;
  final String searchQuery;
  final DateTimeRange? dateRange;

  const MistakeFilter({
    this.lessonId,
    this.subject,
    this.difficulty,
    this.reason,
    this.tag,
    this.searchQuery = '',
    this.dateRange,
  });

  bool get hasActiveFilters =>
      lessonId != null ||
      subject != null ||
      difficulty != null ||
      reason != null ||
      tag != null ||
      dateRange != null;

  MistakeFilter copyWith({
    String? lessonId,
    String? subject,
    String? difficulty,
    String? reason,
    String? tag,
    String? searchQuery,
    DateTimeRange? dateRange,
    bool clearLesson = false,
    bool clearSubject = false,
    bool clearDifficulty = false,
    bool clearReason = false,
    bool clearTag = false,
    bool clearDate = false,
  }) {
    return MistakeFilter(
      lessonId: clearLesson ? null : (lessonId ?? this.lessonId),
      subject: clearSubject ? null : (subject ?? this.subject),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      reason: clearReason ? null : (reason ?? this.reason),
      tag: clearTag ? null : (tag ?? this.tag),
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: clearDate ? null : (dateRange ?? this.dateRange),
    );
  }
}

final mistakeFilterProvider = StateNotifierProvider<MistakeFilterNotifier, MistakeFilter>((ref) {
  return MistakeFilterNotifier();
});

class MistakeFilterNotifier extends StateNotifier<MistakeFilter> {
  MistakeFilterNotifier() : super(const MistakeFilter());

  void setLessonId(String? id) => state = state.copyWith(lessonId: id, clearSubject: true);
  void setSubject(String? subject) => state = state.copyWith(subject: subject);
  void setDifficulty(String? difficulty) => state = state.copyWith(difficulty: difficulty);
  void setReason(String? reason) => state = state.copyWith(reason: reason);
  void setTag(String? tag) => state = state.copyWith(tag: tag);
  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setDateRange(DateTimeRange? range) => state = state.copyWith(dateRange: range);

  void clearLesson() => state = state.copyWith(clearLesson: true, clearSubject: true);
  void clearSubject() => state = state.copyWith(clearSubject: true);
  void clearDifficulty() => state = state.copyWith(clearDifficulty: true);
  void clearReason() => state = state.copyWith(clearReason: true);
  void clearTag() => state = state.copyWith(clearTag: true);
  void clearDate() => state = state.copyWith(clearDate: true);

  void clearAll() {
    state = const MistakeFilter();
  }
}

// 3. Filtered Mistakes Provider
final filteredMistakesProvider = Provider<List<Mistake>>((ref) {
  final mistakes = ref.watch(mistakeListProvider);
  final filter = ref.watch(mistakeFilterProvider);

  return mistakes.where((mistake) {
    // Lesson filter
    if (filter.lessonId != null && mistake.lessonId != filter.lessonId) {
      return false;
    }
    // Subject filter
    if (filter.subject != null && mistake.subject.toLowerCase() != filter.subject!.toLowerCase()) {
      return false;
    }
    // Difficulty filter
    if (filter.difficulty != null && mistake.difficulty != filter.difficulty) {
      return false;
    }
    // Reason filter
    if (filter.reason != null && mistake.reason != filter.reason) {
      return false;
    }
    // Tag filter
    if (filter.tag != null && !mistake.tags.contains(filter.tag)) {
      return false;
    }
    // Date filter
    if (filter.dateRange != null) {
      final start = DateUtils.dateOnly(filter.dateRange!.start);
      final end = DateUtils.dateOnly(filter.dateRange!.end).add(const Duration(days: 1));
      if (mistake.createdAt.isBefore(start) || mistake.createdAt.isAfter(end)) {
        return false;
      }
    }
    // Text Search filter (matches subjects, notes, books, tags, exams)
    if (filter.searchQuery.trim().isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      final inSubject = mistake.subject.toLowerCase().contains(query);
      final inNote = mistake.note?.toLowerCase().contains(query) ?? false;
      final inBook = mistake.sourceBook?.toLowerCase().contains(query) ?? false;
      final inExam = mistake.mockExamName?.toLowerCase().contains(query) ?? false;
      final inTag = mistake.tags.any((t) => t.toLowerCase().contains(query));
      
      if (!inSubject && !inNote && !inBook && !inExam && !inTag) {
        return false;
      }
    }
    return true;
  }).toList();
});
