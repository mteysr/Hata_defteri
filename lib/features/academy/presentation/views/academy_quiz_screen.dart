import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/academy_controller.dart';
import '../controllers/academy_stats_provider.dart';
import '../../domain/models/academy_question.dart';
import '../../domain/models/academy_review_question.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../lessons/data/models/lesson.dart';
import '../../../mistakes/domain/models/mistake.dart';
import '../../../mistakes/presentation/controllers/mistake_controller.dart';

class AcademyQuizScreen extends ConsumerStatefulWidget {
  final String mode; // 'daily' or 'review'

  const AcademyQuizScreen({super.key, required this.mode});

  @override
  ConsumerState<AcademyQuizScreen> createState() => _AcademyQuizScreenState();
}

class _AcademyQuizScreenState extends ConsumerState<AcademyQuizScreen> {
  int _currentIndex = 0;
  final Set<int> _importedQuestionIds = {};
  
  // Local state for review quiz answers (daily quiz answers are persisted in DailyQuizState)
  final Map<int, int> _reviewAnswers = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDaily = widget.mode == 'daily';

    // 1. Resolve Questions based on mode
    List<AcademyQuestion> questions = [];
    bool isCompleted = false;
    final isPractice = widget.mode == 'practice';
    final isPast = widget.mode == 'past';

    if (isDaily) {
      final dailyState = ref.watch(dailyQuizProvider);
      questions = dailyState.questions;
      isCompleted = dailyState.isCompleted;
    } else if (isPractice) {
      final practiceState = ref.watch(practiceQuizProvider);
      questions = practiceState.questions;
      isCompleted = practiceState.isCompleted;
    } else if (isPast) {
      final pastState = ref.watch(pastQuizProvider);
      questions = pastState.questions;
      isCompleted = pastState.isCompleted;
    } else {
      final reviewList = ref.watch(dueAcademyReviewQuestionsProvider);
      questions = reviewList.map((q) {
        return AcademyQuestion(
          id: q.questionId,
          category: q.category,
          topic: q.topic,
          difficulty: q.difficulty,
          question: q.question,
          options: q.options,
          correctAnswer: q.correctAnswer,
          explanation: q.explanation,
        );
      }).toList();
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(isDaily ? 'Günün Soruları' : (isPractice ? 'Pratik Testi' : (isPast ? 'Çıkmış Sorular' : 'Tekrar Soruları')))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Soru Bulunamadı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isDaily 
                      ? 'Günün soruları henüz yüklenemedi. Lütfen daha sonra deneyin.' 
                      : 'Bugün tekrar etmeniz gereken bir soru bulunmuyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Akademiye Dön'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Index safety check
    if (_currentIndex >= questions.length) {
      _currentIndex = questions.length - 1;
    }

    final question = questions[_currentIndex];
    final flaggedIds = ref.watch(flaggedAcademyQuestionsProvider);
    final isFlagged = flaggedIds.contains(question.id);

    // Get answered option index
    int? selectedIndex;
    if (isDaily) {
      selectedIndex = ref.watch(dailyQuizProvider).answers[question.id];
    } else if (isPractice) {
      selectedIndex = ref.watch(practiceQuizProvider).answers[question.id];
    } else if (isPast) {
      selectedIndex = ref.watch(pastQuizProvider).answers[question.id];
    } else {
      selectedIndex = _reviewAnswers[question.id];
    }

    final hasAnswered = selectedIndex != null;
    final isCorrect = hasAnswered && selectedIndex == question.correctAnswer;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDaily ? 'Günün Soruları' : (isPractice ? 'Pratik Testi' : (isPast ? 'Çıkmış Sorular' : 'Tekrar Soruları'))),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFlagged ? Icons.bookmark : Icons.bookmark_border,
              color: isFlagged ? AppColors.warning : null,
            ),
            onPressed: () {
              ref.read(flaggedAcademyQuestionsProvider.notifier).toggleFlag(question.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFlagged ? 'Sorunun işareti kaldırıldı' : 'Soru işaretlendi'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Soruyu İşaretle',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kalan Soru: ${questions.length - _currentIndex}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '${_currentIndex + 1} / ${questions.length}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / questions.length,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),

              // Card containing question
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Metadata Tags
                        Row(
                          children: [
                            _buildMetaTag(question.category, _getCategoryColor(question.category), theme),
                            const SizedBox(width: 8),
                            _buildMetaTag(question.difficulty, _getDifficultyColor(question.difficulty), theme),
                            const Spacer(),
                            if (question.topic.isNotEmpty)
                              Text(
                                question.topic,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Scrollable Question & Options & Explanations
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Question text
                                Text(
                                  question.question,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Options List
                                ...List.generate(4, (index) {
                                  final optionText = question.options[index];
                                  final label = String.fromCharCode(65 + index); // A, B, C, D

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildOptionButton(
                                      label: label,
                                      text: optionText,
                                      index: index,
                                      selectedIndex: selectedIndex,
                                      correctIndex: question.correctAnswer,
                                      hasAnswered: hasAnswered,
                                      onTap: () => _onOptionSelected(question, index),
                                      theme: theme,
                                    ),
                                  );
                                }),

                                // Explanation reveal panel
                                if (hasAnswered) ...[
                                  const Divider(height: 32),
                                  _buildExplanationPanel(question, isCorrect, theme),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Navigation controls bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  OutlinedButton.icon(
                    onPressed: _currentIndex > 0
                        ? () {
                            setState(() {
                              _currentIndex--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Geri'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),

                  // Next / Finish button
                  FilledButton.icon(
                    onPressed: hasAnswered ? () => _onNextPressed(questions) : null,
                    label: Text(_currentIndex == questions.length - 1 ? 'Sonuçları Gör' : 'İleri'),
                    icon: Icon(_currentIndex == questions.length - 1 ? Icons.done_all : Icons.arrow_forward),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaTag(String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required String text,
    required int index,
    required int? selectedIndex,
    required int correctIndex,
    required bool hasAnswered,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    Color? backgroundColor;
    Color? borderColor;
    Color? textColor;

    if (hasAnswered) {
      if (index == correctIndex) {
        // Correct option is always green
        backgroundColor = AppColors.success.withOpacity(0.12);
        borderColor = AppColors.success;
        textColor = AppColors.success;
      } else if (selectedIndex == index) {
        // Incorrect chosen option is red
        backgroundColor = AppColors.error.withOpacity(0.12);
        borderColor = AppColors.error;
        textColor = AppColors.error;
      } else {
        // Unselected, non-correct options are dimmed
        backgroundColor = theme.colorScheme.surfaceVariant.withOpacity(0.3);
        borderColor = theme.colorScheme.outline.withOpacity(0.2);
        textColor = theme.colorScheme.onSurface.withOpacity(0.5);
      }
    } else {
      // Normal interactive state
      final isSelected = selectedIndex == index;
      backgroundColor = isSelected ? theme.colorScheme.primary.withOpacity(0.08) : null;
      borderColor = isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.4);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasAnswered ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor ?? theme.colorScheme.outline.withOpacity(0.4),
              width: borderColor != null ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Circle Label A, B, C, D
              CircleAvatar(
                radius: 14,
                backgroundColor: textColor?.withOpacity(0.15) ?? theme.colorScheme.surfaceVariant,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: hasAnswered ? textColor ?? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                    fontWeight: (selectedIndex == index || (hasAnswered && index == correctIndex))
                        ? FontWeight.bold
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationPanel(AcademyQuestion question, bool isCorrect, ThemeData theme) {
    final isImported = _importedQuestionIds.contains(question.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.success.withOpacity(0.06) : AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Tebrikler, Doğru Cevap!' : 'Yanlış Cevap!',
                style: TextStyle(
                  color: isCorrect ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Doğru Cevap: ${String.fromCharCode(65 + question.correctAnswer)} şıkkı.',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isImported ? null : () => _importToMistakesBook(question),
              icon: Icon(
                isImported ? Icons.bookmark : Icons.bookmark_add_outlined,
                size: 18,
              ),
              label: Text(
                isImported ? 'Hata Defterine Eklendi' : 'Hata Defterime Ekle',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isCorrect ? AppColors.success : AppColors.error,
                side: BorderSide(
                  color: (isCorrect ? AppColors.success : AppColors.error).withOpacity(0.4),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importToMistakesBook(AcademyQuestion question) async {
    try {
      final lessonsBox = Hive.box<Lesson>('lessons_box');
      final lesson = lessonsBox.values.firstWhere(
        (l) => l.name == question.category,
        orElse: () => lessonsBox.values.first,
      );

      final String lessonId = lesson.id;
      final String formattedNote = 
          "${question.question}\n\n"
          "A) ${question.options[0]}\n"
          "B) ${question.options[1]}\n"
          "C) ${question.options[2]}\n"
          "D) ${question.options[3]}\n"
          "///\n"
          "Doğru Cevap: ${String.fromCharCode(65 + question.correctAnswer)} şıkkı.\n\n"
          "Açıklama:\n${question.explanation}";

      // Map difficulty
      String diff = 'MEDIUM';
      if (question.difficulty == 'Kolay') diff = 'EASY';
      if (question.difficulty == 'Zor') diff = 'HARD';

      final newMistake = Mistake(
        id: const Uuid().v4(),
        lessonId: lessonId,
        subject: question.topic,
        sourceBook: 'Genel Kültür Akademisi',
        difficulty: diff,
        reason: 'LACK_OF_KNOWLEDGE',
        note: formattedNote,
        tags: ['Akademi', question.category],
        questionImagePath: '',
        createdAt: DateTime.now(),
        nextReviewAt: DateTime.now().add(const Duration(days: 1)),
        reviewStage: 0,
        isCompleted: false,
        reviewAttempts: [],
      );

      await ref.read(mistakeListProvider.notifier).addMistake(newMistake);

      setState(() {
        _importedQuestionIds.add(question.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soru Hata Defterinize başarıyla eklendi! 🎉')),
      );
    } catch (e) {
      debugPrint('Error importing question to mistakes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soru kaydedilirken bir hata oluştu.')),
      );
    }
  }

  void _onOptionSelected(AcademyQuestion question, int index) {
    final isDaily = widget.mode == 'daily';
    final isPractice = widget.mode == 'practice';
    final isPast = widget.mode == 'past';
    if (isDaily) {
      ref.read(dailyQuizProvider.notifier).saveAnswer(question.id, index);
    } else if (isPractice) {
      ref.read(practiceQuizProvider.notifier).savePracticeAnswer(question.id, index);
    } else if (isPast) {
      ref.read(pastQuizProvider.notifier).savePastAnswer(question.id, index);
    } else {
      setState(() {
        _reviewAnswers[question.id] = index;
      });

      // Submit immediately to review Spaced Repetition queue
      final isCorrect = index == question.correctAnswer;
      ref.read(academyReviewControllerProvider).submitReviewAnswer(question.id, isCorrect);
    }
  }

  void _onNextPressed(List<AcademyQuestion> questions) {
    if (_currentIndex < questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // Last question finished, navigate to results screen
      final isDaily = widget.mode == 'daily';
      final isPractice = widget.mode == 'practice';
      final isPast = widget.mode == 'past';
      
      int correct = 0;
      int incorrect = 0;
      final Map<String, int> categoryTotal = {};
      final Map<String, int> categoryCorrect = {};

      for (var q in questions) {
        int? answer;
        if (isDaily) {
          answer = ref.read(dailyQuizProvider).answers[q.id];
        } else if (isPractice) {
          answer = ref.read(practiceQuizProvider).answers[q.id];
        } else if (isPast) {
          answer = ref.read(pastQuizProvider).answers[q.id];
        } else {
          answer = _reviewAnswers[q.id];
        }
        final isCorrect = answer == q.correctAnswer;
        
        if (isCorrect) correct++; else incorrect++;
        
        categoryTotal[q.category] = (categoryTotal[q.category] ?? 0) + 1;
        if (isCorrect) {
          categoryCorrect[q.category] = (categoryCorrect[q.category] ?? 0) + 1;
        }
      }

      final Map<String, double> categoryStats = {};
      for (var cat in categoryTotal.keys) {
        final total = categoryTotal[cat]!;
        final corr = categoryCorrect[cat] ?? 0;
        categoryStats[cat] = (corr / total) * 100;
      }

      if (isDaily) {
        ref.read(dailyQuizProvider.notifier).submitQuiz();
      } else if (isPractice) {
        ref.read(practiceQuizProvider.notifier).submitPracticeQuiz();
      } else if (isPast) {
        ref.read(pastQuizProvider.notifier).submitPastQuiz();
      }

      // Pop quiz screen and push results screen
      context.replace('/academy-result', extra: {
        'total': questions.length,
        'correct': correct,
        'incorrect': incorrect,
        'categoryStats': categoryStats,
      });
    }
  }

  Color _getCategoryColor(String category) {
    if (category == 'Tarih') return AppColors.history;
    if (category == 'Coğrafya') return AppColors.geography;
    if (category == 'Vatandaşlık') return AppColors.civics;
    return AppColors.lightPrimary;
  }

  Color _getDifficultyColor(String difficulty) {
    if (difficulty == 'Kolay') return AppColors.success;
    if (difficulty == 'Orta') return AppColors.warning;
    if (difficulty == 'Zor') return AppColors.error;
    return AppColors.lightPrimary;
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Çıkış Onayı'),
          content: const Text(
            'Çözmekte olduğunuz testi yarıda kesmek istediğinizden emin misiniz?\n\n'
            'Not: Cevaplarınız kaydedilecek ancak bitirilmeyen testlerin analizleri istatistiklere yansımaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Devam Et'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                context.pop(); // exit quiz screen
              },
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }
}
