import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../lessons/data/models/lesson.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../lessons/presentation/controllers/lesson_controller.dart';
import '../../../mistakes/domain/models/mistake.dart';
import '../../../mistakes/presentation/controllers/mistake_controller.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _currentIndex = 0;
  bool _revealSolution = false;
  String? _selectedLessonId;

  String get _selectedLessonName {
    if (_selectedLessonId == 'all') return 'Tüm Dersler';
    final lessons = ref.read(lessonListProvider);
    final lesson = lessons.cast<Lesson?>().firstWhere(
          (l) => l?.id == _selectedLessonId,
          orElse: () => null,
        );
    return lesson?.name ?? 'Tekrarlar';
  }

  @override
  Widget build(BuildContext context) {
    final mistakes = ref.watch(mistakeListProvider);
    final lessons = ref.watch(lessonListProvider);
    final theme = Theme.of(context);

    // Calculate all due mistakes
    final today = DateUtils.dateOnly(DateTime.now());
    final allDueMistakes = mistakes.where((m) {
      if (m.isCompleted) return false;
      final nextReview = DateUtils.dateOnly(m.nextReviewAt);
      return nextReview.isBefore(today) || nextReview.isAtSameMomentAs(today);
    }).toList();

    if (allDueMistakes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bugünün Tekrarları'),
        ),
        body: _buildEmptyState(context),
      );
    }

    // Show category selector if nothing is selected yet
    if (_selectedLessonId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bugünün Tekrarları'),
        ),
        body: _buildCategorySelector(context, allDueMistakes, lessons),
      );
    }

    // Filter dueMistakes based on active selection
    final dueMistakes = _selectedLessonId == 'all'
        ? allDueMistakes
        : allDueMistakes.where((m) => m.lessonId == _selectedLessonId).toList();

    // If current selected lesson has no more questions due (e.g. done), clear selection
    if (dueMistakes.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedLessonId = null;
          _currentIndex = 0;
        });
      });
      return Scaffold(
        appBar: AppBar(title: Text(_selectedLessonName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If current index is out of bounds, reset it
    if (_currentIndex >= dueMistakes.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedLessonName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedLessonId = null;
              _currentIndex = 0;
              _revealSolution = false;
            });
          },
        ),
      ),
      body: _buildReviewFlow(context, dueMistakes, lessons),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tebrikler!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Bugün tekrar edilmesi gereken soru bulunmuyor. Harika bir iş çıkardın!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: const Text('Panoya Dön'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewFlow(
    BuildContext context,
    List<Mistake> dueMistakes,
    List<dynamic> lessons,
  ) {
    final theme = Theme.of(context);
    final mistake = dueMistakes[_currentIndex];
    final lessonObj = lessons.cast<Lesson?>().firstWhere(
          (l) => l?.id == mistake.lessonId,
          orElse: () => null,
        );
    final lessonColor = lessonObj != null ? Color(lessonObj.colorValue) : theme.colorScheme.primary;
    final lessonName = lessonObj?.name ?? 'Bilinmeyen Ders';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress Indicator Text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kalan Soru: ${dueMistakes.length - _currentIndex}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${_currentIndex + 1} / ${dueMistakes.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / dueMistakes.length,
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 20),

            // Card Container
            Expanded(
              child: Card(
                elevation: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Scrollable content inside card
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subject Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: lessonColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$lessonName - ${mistake.subject}',
                                  style: TextStyle(
                                    color: lessonColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Mistake Question Image
                              Text(
                                'Soru:',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildPhotoView(mistake.questionImageFile, mistake),
                              const SizedBox(height: 20),

                              if (_revealSolution) ...[
                                const Divider(height: 32),
                                // Correct Answer Option
                                if (mistake.correctAnswerOption != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Soru Doğru Cevap Şıkkı:',
                                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            mistake.correctAnswerOption!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                // Notes
                                if (mistake.note != null && mistake.note!.isNotEmpty) ...[
                                  Text(
                                    mistake.tags.contains('Akademi') ? 'Cevap & Açıklama:' : 'Çalışma Notları:',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: mistake.tags.contains('Akademi')
                                          ? AppColors.success.withOpacity(0.06)
                                          : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: mistake.tags.contains('Akademi')
                                          ? Border.all(color: AppColors.success.withOpacity(0.15))
                                          : null,
                                    ),
                                    child: Text(
                                      (mistake.tags.contains('Akademi') && mistake.note!.contains('///'))
                                          ? mistake.note!.split('///')[1].trim()
                                          : mistake.note!,
                                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Solution Image
                                if (mistake.solutionImageFile != null) ...[
                                  Text(
                                    'Çözüm Fotoğrafı:',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildPhotoView(mistake.solutionImageFile!),
                                  const SizedBox(height: 20),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Actions panel bottom of card
                      if (!_revealSolution)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _revealSolution = true;
                            });
                          },
                          child: Container(
                            color: theme.colorScheme.primaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.visibility, color: theme.colorScheme.onPrimaryContainer),
                                const SizedBox(width: 8),
                                Text(
                                  'Çözümü Göster',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _handleAnswer(dueMistakes, false),
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Yanlış Çözdüm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _handleAnswer(dueMistakes, true),
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Doğru Çözdüm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoView(String path, [Mistake? mistake]) {
    final hasFile = path.isNotEmpty && File(path).isAbsolute && File(path).existsSync();

    if (!hasFile && mistake != null && mistake.tags.contains('Akademi')) {
      final parts = (mistake.note ?? '').split('///');
      final questionText = parts[0].trim();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
        ),
        child: Text(
          questionText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
        ),
      );
    }

    if (path.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      );
    }

    final file = File(path);
    if (!file.isAbsolute || !file.existsSync()) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleAnswer(List<Mistake> dueMistakes, bool isCorrect) {
    final mistake = dueMistakes[_currentIndex];
    
    // Save attempts and schedule next date
    ref.read(mistakeListProvider.notifier).recordReviewAttempt(mistake.id, isCorrect);

    if (_currentIndex < dueMistakes.length - 1) {
      setState(() {
        _currentIndex++;
        _revealSolution = false;
      });
    } else {
      // Completed all reviews for today
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tebrikler! 🎉'),
          content: Text(_selectedLessonId == 'all'
              ? 'Bugünün tüm tekrarlarını başarıyla tamamladınız. Öğrenmeye devam edin!'
              : 'Seçili dersin tüm tekrarlarını başarıyla tamamladınız! Diğer derslerle devam edebilirsiniz.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                setState(() {
                  _selectedLessonId = null;
                  _currentIndex = 0;
                  _revealSolution = false;
                });
              },
              child: const Text('Devam Et'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
    List<Mistake> allDueMistakes,
    List<dynamic> lessons,
  ) {
    final theme = Theme.of(context);

    // Group counts
    final Map<String, int> lessonCounts = {};
    for (var m in allDueMistakes) {
      lessonCounts[m.lessonId] = (lessonCounts[m.lessonId] ?? 0) + 1;
    }

    // Get list of lessons that have questions due
    final dueLessons = lessons.cast<Lesson>().where((l) => lessonCounts.containsKey(l.id)).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Tekrar Zamanı!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Bugün tekrar etmen gereken toplam ${allDueMistakes.length} soru bulunuyor. İstediğin dersten başlayarak hafızanı tazeleyebilirsin.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Ders Seçimi',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Tüm Dersler Card
          _buildCategoryCard(
            context,
            title: 'Tüm Dersler',
            count: allDueMistakes.length,
            icon: Icons.layers,
            color: theme.colorScheme.primary,
            onTap: () {
              setState(() {
                _selectedLessonId = 'all';
                _currentIndex = 0;
                _revealSolution = false;
              });
            },
          ),
          const SizedBox(height: 12),

          // Individual Lesson Cards
          ...dueLessons.map((lesson) {
            final count = lessonCounts[lesson.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCategoryCard(
                context,
                title: lesson.name,
                count: count,
                icon: AppConstants.getIconData(lesson.iconCodePoint),
                color: Color(lesson.colorValue),
                onTap: () {
                  setState(() {
                    _selectedLessonId = lesson.id;
                    _currentIndex = 0;
                    _revealSolution = false;
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Title & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count Soru Bekliyor',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
