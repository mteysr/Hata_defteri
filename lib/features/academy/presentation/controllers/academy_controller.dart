import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/academy_question.dart';
import '../../domain/models/academy_review_question.dart';
import '../../domain/models/academy_answer_history.dart';
import '../../../../core/constants/app_constants.dart';

// --- 1. Static Questions Loader Provider ---
final academyQuestionsProvider = FutureProvider<List<AcademyQuestion>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/questions/academy_questions.json');
  final List<dynamic> jsonList = json.decode(jsonStr);
  return jsonList.map((e) => AcademyQuestion.fromJson(e)).toList();
});

// --- 2. Flagged Questions State Notifier ---
final flaggedAcademyQuestionsProvider = StateNotifierProvider<FlaggedAcademyQuestionsNotifier, Set<int>>((ref) {
  return FlaggedAcademyQuestionsNotifier();
});

class FlaggedAcademyQuestionsNotifier extends StateNotifier<Set<int>> {
  FlaggedAcademyQuestionsNotifier() : super({}) {
    _loadFlagged();
  }

  void _loadFlagged() {
    try {
      final box = Hive.box('academy_settings_box');
      final list = box.get('flagged_question_ids', defaultValue: <int>[]) as List<dynamic>;
      state = list.cast<int>().toSet();
    } catch (_) {}
  }

  void toggleFlag(int questionId) {
    final box = Hive.box('academy_settings_box');
    final updated = Set<int>.from(state);
    if (updated.contains(questionId)) {
      updated.remove(questionId);
    } else {
      updated.add(questionId);
    }
    box.put('flagged_question_ids', updated.toList());
    state = updated;
  }
}

// --- 3. Daily Quiz State Class ---
class DailyQuizState {
  final List<AcademyQuestion> questions;
  final Map<int, int?> answers; // questionId -> selectedIndex
  final bool isCompleted;
  final bool isLoading;

  DailyQuizState({
    required this.questions,
    required this.answers,
    required this.isCompleted,
    this.isLoading = false,
  });

  DailyQuizState copyWith({
    List<AcademyQuestion>? questions,
    Map<int, int?>? answers,
    bool? isCompleted,
    bool? isLoading,
  }) {
    return DailyQuizState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- 4. Daily Quiz State Notifier ---
final dailyQuizProvider = StateNotifierProvider<DailyQuizNotifier, DailyQuizState>((ref) {
  return DailyQuizNotifier(ref);
});

class DailyQuizNotifier extends StateNotifier<DailyQuizState> {
  final Ref _ref;

  DailyQuizNotifier(this._ref) : super(DailyQuizState(questions: [], answers: {}, isCompleted: false)) {
    loadOrGenerateQuiz();
  }

  Future<void> loadOrGenerateQuiz() async {
    state = state.copyWith(isLoading: true);
    
    // Wait for static questions to load
    final allQuestions = await _ref.read(academyQuestionsProvider.future);
    if (allQuestions.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final box = Hive.box('academy_settings_box');
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = box.get('daily_quiz_date') as String?;

    if (savedDate == todayStr) {
      // Load saved quiz
      final savedIds = (box.get('daily_quiz_question_ids', defaultValue: []) as List<dynamic>).cast<int>();
      final savedAnswersList = box.get('daily_quiz_answers', defaultValue: {}) as Map<dynamic, dynamic>;
      final isCompleted = box.get('daily_quiz_completed', defaultValue: false) as bool;

      final Map<int, int?> savedAnswers = {};
      for (var entry in savedAnswersList.entries) {
        savedAnswers[entry.key as int] = entry.value as int?;
      }

      final quizQuestions = savedIds.map((id) {
        return allQuestions.firstWhere((q) => q.id == id, orElse: () => allQuestions.first);
      }).toList();

      state = DailyQuizState(
        questions: quizQuestions,
        answers: savedAnswers,
        isCompleted: isCompleted,
        isLoading: false,
      );
    } else {
      // Generate new daily quiz
      final recentIds = (box.get('recent_question_ids', defaultValue: []) as List<dynamic>).cast<int>();
      
      final selectedIds = selectQuestionsForDailyQuiz(allQuestions, recentIds);
      
      // Cache settings
      box.put('daily_quiz_date', todayStr);
      box.put('daily_quiz_question_ids', selectedIds);
      box.put('daily_quiz_answers', <int, int?>{});
      box.put('daily_quiz_completed', false);

      // Update recency list (limit to min(poolSize ~/ 2, 15) or 6 to avoid starvation)
      final newRecent = List<int>.from(recentIds)..addAll(selectedIds);
      final recencyLimit = (allQuestions.length ~/ 2).clamp(5, 15);
      if (newRecent.length > recencyLimit) {
        newRecent.removeRange(0, newRecent.length - recencyLimit);
      }
      box.put('recent_question_ids', newRecent);

      final quizQuestions = selectedIds.map((id) {
        return allQuestions.firstWhere((q) => q.id == id);
      }).toList();

      state = DailyQuizState(
        questions: quizQuestions,
        answers: {},
        isCompleted: false,
        isLoading: false,
      );
    }
  }

  // Pure function to select 5 random category-diverse questions
  List<int> selectQuestionsForDailyQuiz(List<AcademyQuestion> pool, List<int> recentIds) {
    // Filter out recent questions
    var available = pool.where((q) => !recentIds.contains(q.id)).toList();
    if (available.length < 5) {
      available = List<AcademyQuestion>.from(pool);
    }

    final historyPool = available.where((q) => q.category == 'Tarih').toList();
    final geographyPool = available.where((q) => q.category == 'Coğrafya').toList();
    final civicsPool = available.where((q) => q.category == 'Vatandaşlık').toList();

    historyPool.shuffle();
    geographyPool.shuffle();
    civicsPool.shuffle();

    final selected = <AcademyQuestion>[];

    // Try round-robin style to get diversity: 2 Tarih, 2 Coğrafya, 1 Vatandaşlık (or fallback)
    if (historyPool.isNotEmpty) selected.add(historyPool.removeLast());
    if (geographyPool.isNotEmpty) selected.add(geographyPool.removeLast());
    if (civicsPool.isNotEmpty) selected.add(civicsPool.removeLast());

    // Second round
    if (historyPool.isNotEmpty) selected.add(historyPool.removeLast());
    if (geographyPool.isNotEmpty) selected.add(geographyPool.removeLast());

    // Fallback: fill in up to 5 from remaining available combined pool
    if (selected.length < 5) {
      final remaining = [...historyPool, ...geographyPool, ...civicsPool];
      remaining.shuffle();
      while (selected.length < 5 && remaining.isNotEmpty) {
        selected.add(remaining.removeLast());
      }
    }

    // Cut to exactly 5 questions
    final result = selected.take(5).toList();
    result.shuffle();
    return result.map((q) => q.id).toList();
  }

  void saveAnswer(int questionId, int selectedIndex) {
    if (state.isCompleted) return;
    
    final updatedAnswers = Map<int, int?>.from(state.answers);
    updatedAnswers[questionId] = selectedIndex;

    final box = Hive.box('academy_settings_box');
    box.put('daily_quiz_answers', updatedAnswers);

    state = state.copyWith(answers: updatedAnswers);
  }

  Future<void> submitQuiz() async {
    if (state.isCompleted) return;

    final historyBox = Hive.box<AcademyAnswerHistory>('academy_history_box');
    final reviewBox = Hive.box<AcademyReviewQuestion>('academy_review_box');
    final box = Hive.box('academy_settings_box');
    final now = DateTime.now();

    for (var question in state.questions) {
      final answer = state.answers[question.id];
      final isCorrect = answer == question.correctAnswer;

      // 1. Log to history box for analytics
      final historyLog = AcademyAnswerHistory(
        id: const Uuid().v4(),
        questionId: question.id,
        category: question.category,
        topic: question.topic,
        isCorrect: isCorrect,
        answeredAt: now,
      );
      await historyBox.add(historyLog);

      // 2. If incorrect, add to spaced repetition review questions
      if (!isCorrect) {
        final existingIndex = reviewBox.values.toList().indexWhere((q) => q.questionId == question.id);
        
        if (existingIndex != -1) {
          final existing = reviewBox.getAt(existingIndex)!;
          // Reset existing review stage to 0 and set next review date to 1 day later
          final updated = existing.copyWith(
            reviewStage: 0,
            nextReviewAt: now.add(const Duration(days: 1)),
            isCompleted: false,
          );
          await reviewBox.putAt(existingIndex, updated);
        } else {
          // Add new review question
          final reviewQuestion = AcademyReviewQuestion(
            questionId: question.id,
            category: question.category,
            topic: question.topic,
            difficulty: question.difficulty,
            question: question.question,
            options: question.options,
            correctAnswer: question.correctAnswer,
            explanation: question.explanation,
            reviewStage: 0,
            nextReviewAt: now.add(const Duration(days: 1)),
            isCompleted: false,
            createdAt: now,
          );
          await reviewBox.add(reviewQuestion);
        }
      }
    }

    box.put('daily_quiz_completed', true);
    state = state.copyWith(isCompleted: true);
  }
}

// --- 5. Spaced Repetition Due Questions List Provider ---
final dueAcademyReviewQuestionsProvider = Provider<List<AcademyReviewQuestion>>((ref) {
  final reviewBox = Hive.box<AcademyReviewQuestion>('academy_review_box');
  final today = DateUtils.dateOnly(DateTime.now());
  
  return reviewBox.values.where((q) {
    if (q.isCompleted) return false;
    final nextReview = DateUtils.dateOnly(q.nextReviewAt);
    return nextReview.isBefore(today) || nextReview.isAtSameMomentAs(today);
  }).toList();
});

// --- 6. Spaced Repetition Review Controller ---
final academyReviewControllerProvider = Provider((ref) => AcademyReviewController(ref));

class AcademyReviewController {
  final Ref _ref;

  AcademyReviewController(this._ref);

  Future<void> submitReviewAnswer(int questionId, bool isCorrect) async {
    final reviewBox = Hive.box<AcademyReviewQuestion>('academy_review_box');
    final historyBox = Hive.box<AcademyAnswerHistory>('academy_history_box');
    final now = DateTime.now();

    final itemIndex = reviewBox.values.toList().indexWhere((q) => q.questionId == questionId);
    if (itemIndex == -1) return;

    final question = reviewBox.getAt(itemIndex)!;

    // Log to answer history
    final historyLog = AcademyAnswerHistory(
      id: const Uuid().v4(),
      questionId: questionId,
      category: question.category,
      topic: question.topic,
      isCorrect: isCorrect,
      answeredAt: now,
    );
    await historyBox.add(historyLog);

    // Spaced repetition progression: 1, 3, 7, 15, 30 days
    final List<int> reviewIntervals = [1, 3, 7, 15, 30];
    int nextStage = 0;
    DateTime nextReview;
    bool isCompleted = false;

    if (isCorrect) {
      nextStage = question.reviewStage + 1;
      if (nextStage >= reviewIntervals.length) {
        nextStage = reviewIntervals.length - 1;
        isCompleted = true;
        nextReview = now.add(const Duration(days: 3650)); // Mastered, don't show for years
      } else {
        nextReview = now.add(Duration(days: reviewIntervals[nextStage]));
      }
    } else {
      // Reset on incorrect answer
      nextStage = 0;
      nextReview = now.add(const Duration(days: 1));
    }

    final updated = question.copyWith(
      reviewStage: nextStage,
      nextReviewAt: nextReview,
      isCompleted: isCompleted,
    );

    await reviewBox.putAt(itemIndex, updated);
  }
}

// --- 7. Practice Quiz State Class ---
class PracticeQuizState {
  final List<AcademyQuestion> questions;
  final Map<int, int?> answers; // questionId -> selectedIndex
  final bool isCompleted;
  final bool isLoading;

  PracticeQuizState({
    required this.questions,
    required this.answers,
    required this.isCompleted,
    this.isLoading = false,
  });

  PracticeQuizState copyWith({
    List<AcademyQuestion>? questions,
    Map<int, int?>? answers,
    bool? isCompleted,
    bool? isLoading,
  }) {
    return PracticeQuizState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- 8. Practice Quiz State Notifier ---
final practiceQuizProvider = StateNotifierProvider<PracticeQuizNotifier, PracticeQuizState>((ref) {
  return PracticeQuizNotifier(ref);
});

class PracticeQuizNotifier extends StateNotifier<PracticeQuizState> {
  final Ref _ref;

  PracticeQuizNotifier(this._ref) : super(PracticeQuizState(questions: [], answers: {}, isCompleted: false));

  Future<void> startPracticeQuiz({String? category, List<String>? topics, int questionCount = 10}) async {
    state = PracticeQuizState(questions: [], answers: {}, isCompleted: false, isLoading: true);

    final allQuestions = await _ref.read(academyQuestionsProvider.future);
    if (allQuestions.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    // Filter by category if specified (e.g. 'Tarih', 'Coğrafya', 'Vatandaşlık')
    List<AcademyQuestion> filtered = allQuestions;
    if (category != null && category != 'Karma') {
      filtered = allQuestions.where((q) => q.category == category).toList();
    }

    // Filter by topics list if specified and not empty
    if (topics != null && topics.isNotEmpty) {
      filtered = filtered.where((q) => topics.contains(q.topic)).toList();
    }

    // Shuffle and pick configured count (weighted by history to avoid repeats)
    final quizQuestions = _selectWeightedQuestions(filtered, questionCount);

    state = PracticeQuizState(
      questions: quizQuestions,
      answers: {},
      isCompleted: false,
      isLoading: false,
    );
  }

  Future<void> startMistakesQuiz({int questionCount = 10}) async {
    state = PracticeQuizState(questions: [], answers: {}, isCompleted: false, isLoading: true);

    final allQuestions = await _ref.read(academyQuestionsProvider.future);
    if (allQuestions.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final reviewBox = Hive.box<AcademyReviewQuestion>('academy_review_box');
    final wrongIds = reviewBox.values
        .where((q) => !q.isCompleted)
        .map((q) => q.questionId)
        .toSet();

    if (wrongIds.isEmpty) {
      state = PracticeQuizState(questions: [], answers: {}, isCompleted: false, isLoading: false);
      return;
    }

    final wrongQuestions = allQuestions.where((q) => wrongIds.contains(q.id)).toList();
    wrongQuestions.shuffle();
    final quizQuestions = wrongQuestions.take(questionCount).toList();

    state = PracticeQuizState(
      questions: quizQuestions,
      answers: {},
      isCompleted: false,
      isLoading: false,
    );
  }

  void startCustomQuiz(List<AcademyQuestion> customQuestions) {
    state = PracticeQuizState(
      questions: customQuestions,
      answers: {},
      isCompleted: false,
      isLoading: false,
    );
  }

  void savePracticeAnswer(int questionId, int selectedIndex) {
    if (state.isCompleted) return;
    
    final updatedAnswers = Map<int, int?>.from(state.answers);
    updatedAnswers[questionId] = selectedIndex;

    state = state.copyWith(answers: updatedAnswers);
  }

  Future<void> submitPracticeQuiz() async {
    if (state.isCompleted) return;

    final historyBox = Hive.box<AcademyAnswerHistory>('academy_history_box');
    final reviewBox = Hive.box<AcademyReviewQuestion>('academy_review_box');
    final now = DateTime.now();

    for (var question in state.questions) {
      final answer = state.answers[question.id];
      if (answer == null) continue; // skip unanswered questions
      final isCorrect = answer == question.correctAnswer;

      // 1. Log to history box for stats
      final historyLog = AcademyAnswerHistory(
        id: const Uuid().v4(),
        questionId: question.id,
        category: question.category,
        topic: question.topic,
        isCorrect: isCorrect,
        answeredAt: now,
      );
      await historyBox.add(historyLog);

      // 2. If incorrect, add/update in spaced repetition review box
      if (!isCorrect) {
        final existingIndex = reviewBox.values.toList().indexWhere((q) => q.questionId == question.id);
        if (existingIndex != -1) {
          final existing = reviewBox.getAt(existingIndex)!;
          final updated = existing.copyWith(
            reviewStage: 0,
            nextReviewAt: now.add(const Duration(days: 1)),
            isCompleted: false,
          );
          await reviewBox.putAt(existingIndex, updated);
        } else {
          final reviewQuestion = AcademyReviewQuestion(
            questionId: question.id,
            category: question.category,
            topic: question.topic,
            difficulty: question.difficulty,
            question: question.question,
            options: question.options,
            correctAnswer: question.correctAnswer,
            explanation: question.explanation,
            reviewStage: 0,
            nextReviewAt: now.add(const Duration(days: 1)),
            isCompleted: false,
            createdAt: now,
          );
          await reviewBox.add(reviewQuestion);
        }
      }
    }

    state = state.copyWith(isCompleted: true);
  }
}

// --- 9. Past Questions Loader Provider ---
final pastQuestionsProvider = FutureProvider<List<AcademyQuestion>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/questions/past_questions.json');
  final List<dynamic> jsonList = json.decode(jsonStr);
  return jsonList.map((e) => AcademyQuestion.fromJson(e)).toList();
});

// --- 10. Past Quiz State Class ---
class PastQuizState {
  final List<AcademyQuestion> questions;
  final Map<int, int?> answers; // questionId -> selectedIndex
  final bool isCompleted;
  final bool isLoading;

  PastQuizState({
    required this.questions,
    required this.answers,
    required this.isCompleted,
    this.isLoading = false,
  });

  PastQuizState copyWith({
    List<AcademyQuestion>? questions,
    Map<int, int?>? answers,
    bool? isCompleted,
    bool? isLoading,
  }) {
    return PastQuizState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- 11. Past Quiz State Notifier ---
final pastQuizProvider = StateNotifierProvider<PastQuizNotifier, PastQuizState>((ref) {
  return PastQuizNotifier(ref);
});

class PastQuizNotifier extends StateNotifier<PastQuizState> {
  final Ref _ref;

  PastQuizNotifier(this._ref) : super(PastQuizState(questions: [], answers: {}, isCompleted: false));

  Future<void> startPastQuiz({String? category, String? topic, int questionCount = 10}) async {
    state = PastQuizState(questions: [], answers: {}, isCompleted: false, isLoading: true);

    final allQuestions = await _ref.read(pastQuestionsProvider.future);
    if (allQuestions.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    // Filter by category if specified (e.g. 'Tarih', 'Coğrafya', 'Vatandaşlık')
    List<AcademyQuestion> filtered = allQuestions;
    if (category != null && category != 'Karma') {
      filtered = allQuestions.where((q) => q.category == category).toList();
    }

    // Filter by topic if specified
    if (topic != null && topic != 'Tüm Konular') {
      filtered = filtered.where((q) => q.topic == topic).toList();
    }

    // Shuffle and pick configured count (weighted by history to avoid repeats)
    final quizQuestions = _selectWeightedQuestions(filtered, questionCount);

    state = PastQuizState(
      questions: quizQuestions,
      answers: {},
      isCompleted: false,
      isLoading: false,
    );
  }

  void savePastAnswer(int questionId, int selectedIndex) {
    if (state.isCompleted) return;
    
    final updatedAnswers = Map<int, int?>.from(state.answers);
    updatedAnswers[questionId] = selectedIndex;

    state = state.copyWith(answers: updatedAnswers);
  }

  Future<void> submitPastQuiz() async {
    if (state.isCompleted) return;

    final historyBox = Hive.box<AcademyAnswerHistory>('academy_history_box');
    final reviewBox = Hive.box<AcademyReviewQuestion>('academy_review_box');
    final now = DateTime.now();

    for (var question in state.questions) {
      final answer = state.answers[question.id];
      if (answer == null) continue; // skip unanswered questions
      final isCorrect = answer == question.correctAnswer;

      // 1. Log to history box for stats
      final historyLog = AcademyAnswerHistory(
        id: const Uuid().v4(),
        questionId: question.id,
        category: question.category,
        topic: question.topic,
        isCorrect: isCorrect,
        answeredAt: now,
      );
      await historyBox.add(historyLog);

      // 2. If incorrect, add/update in spaced repetition review box
      if (!isCorrect) {
        final existingIndex = reviewBox.values.toList().indexWhere((q) => q.questionId == question.id);
        if (existingIndex != -1) {
          final existing = reviewBox.getAt(existingIndex)!;
          final updated = existing.copyWith(
            reviewStage: 0,
            nextReviewAt: now.add(const Duration(days: 1)),
            isCompleted: false,
          );
          await reviewBox.putAt(existingIndex, updated);
        } else {
          final reviewQuestion = AcademyReviewQuestion(
            questionId: question.id,
            category: question.category,
            topic: question.topic,
            difficulty: question.difficulty,
            question: question.question,
            options: question.options,
            correctAnswer: question.correctAnswer,
            explanation: question.explanation,
            reviewStage: 0,
            nextReviewAt: now.add(const Duration(days: 1)),
            isCompleted: false,
            createdAt: now,
          );
          await reviewBox.add(reviewQuestion);
        }
      }
    }

    state = state.copyWith(isCompleted: true);
  }
}

// --- 12. History-weighted selection algorithm ---
List<AcademyQuestion> _selectWeightedQuestions(List<AcademyQuestion> pool, int count) {
  final historyBox = Hive.box<AcademyAnswerHistory>('academy_history_box');
  final random = Random();
  final now = DateTime.now();

  // 1. Calculate weights for all questions based on attempt history
  final List<MapEntry<AcademyQuestion, double>> weightedList = [];
  for (var question in pool) {
    double weight = 100.0;
    
    // Find answer history for this specific question
    final history = historyBox.values.where((h) => h.questionId == question.id).toList();
    if (history.isNotEmpty) {
      // Sort to get the most recent attempt
      history.sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
      final lastAnswered = history.first.answeredAt;
      final difference = now.difference(lastAnswered);
      final daysSince = difference.inDays;
      final solvedCount = history.length;

      double recencyFactor = 1.0;
      if (difference.inHours < 24) {
        recencyFactor = 0.05; // 95% probability reduction if solved within 24 hours
      } else if (daysSince < 7) {
        recencyFactor = 0.25; // 75% probability reduction if solved within 7 days
      } else if (daysSince < 30) {
        recencyFactor = 0.60; // 40% probability reduction if solved within 30 days
      }

      // Weight decreases as solvedCount increases, and is scaled down by recency
      weight = (100.0 / (1.0 + solvedCount * 1.5)) * recencyFactor;
    }
    
    // Ensure weight is never 0 or negative
    if (weight < 0.1) weight = 0.1;

    weightedList.add(MapEntry(question, weight));
  }

  // 2. Efraimidis and Spirakis weighted random sampling without replacement
  final List<MapEntry<AcademyQuestion, double>> scoredList = weightedList.map((entry) {
    final u = random.nextDouble();
    // Key = u^(1.0 / weight)
    final key = u > 0.0 ? pow(u, 1.0 / entry.value).toDouble() : 0.0;
    return MapEntry(entry.key, key);
  }).toList();

  // 3. Sort by score descending and take the top N
  scoredList.sort((a, b) => b.value.compareTo(a.value));
  return scoredList.take(count).map((entry) => entry.key).toList();
}
