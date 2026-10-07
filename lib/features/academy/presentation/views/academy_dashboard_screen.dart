import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../controllers/academy_controller.dart';
import '../controllers/academy_stats_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'widgets/academy_assistant_card.dart';
import 'widgets/study_timer_section.dart';
import 'widgets/study_duration_chart.dart';
import 'package:hive/hive.dart';
import '../../domain/models/academy_review_question.dart';

class AcademyDashboardScreen extends ConsumerWidget {
  const AcademyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyQuizProvider);
    final dueReviews = ref.watch(dueAcademyReviewQuestionsProvider);
    final stats = ref.watch(academyStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genel Kültür Akademisi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showAcademyInfoDialog(context),
            tooltip: 'Bilgi',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dailyState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(dailyQuizProvider.notifier).loadOrGenerateQuiz();
                ref.invalidate(academyStatsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 0: AI STUDY ASSISTANT ---
                    const AcademyAssistantCard(),
                    const SizedBox(height: 16),



                    // --- SECTION 1: DAILY QUIZ ---
                    _buildDailyQuizCard(context, dailyState, theme),
                    const SizedBox(height: 16),

                    // --- SECTION 2: REVIEWS ---
                    _buildReviewsCard(context, dueReviews, theme),
                    const SizedBox(height: 16),

                    // --- SECTION 2.5: PRACTICE TESTS ---
                    _buildPracticeCard(context, ref, theme),
                    const SizedBox(height: 16),

                    // --- SECTION 2.7: PAST QUESTIONS (ÇIKMIŞ SORULAR) ---
                    _buildPastQuestionsCard(context, ref, theme),
                    const SizedBox(height: 16),

                    // --- SECTION 2.75: STUDY TIMER ---
                    const StudyTimerSection(),
                    const SizedBox(height: 16),

                    // --- SECTION 2.8: COURSE NOTES (DERS NOTLARI) ---
                    _buildCourseNotesCard(context, theme),
                    const SizedBox(height: 16),

                    // --- SECTION 2.9: TOPIC CHECKLIST MATRIX (KONU TAKİP MATRİSİ) ---
                    _buildTopicTrackerCard(context, theme),
                    const SizedBox(height: 24),

                    // --- SECTION 3: STATISTICS ---
                    Text(
                      'Akademi İstatistikleri',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid(stats, theme),
                    const SizedBox(height: 16),
                    _buildCategoryPerformanceCard(stats, theme),
                    const SizedBox(height: 16),
                    _buildStrengthWeaknessCard(stats, theme),
                    const SizedBox(height: 16),
                    _buildProgressChartCard(stats, theme),
                    const SizedBox(height: 16),
                    const StudyDurationChart(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDailyQuizCard(BuildContext context, DailyQuizState state, ThemeData theme) {
    final isCompleted = state.isCompleted;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isCompleted
                ? [AppColors.success.withOpacity(0.08), AppColors.success.withOpacity(0.03)]
                : [theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.primary.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isCompleted ? AppColors.success.withOpacity(0.12) : theme.colorScheme.primary.withOpacity(0.12),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.today,
                    color: isCompleted ? AppColors.success : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Günün Soru Çözümü',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isCompleted ? 'Bugünün sorularını tamamladın!' : 'Her gün yeni 5 soru seni bekliyor.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isCompleted) ...[
              // Completed info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bugünün Çözümü Tamamlandı',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.check, color: AppColors.success),
                ],
              ),
            ] else ...[
              // Start Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/academy-quiz', extra: 'daily'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Günün Sorularını Çöz'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsCard(BuildContext context, List<dynamic> dueReviews, ThemeData theme) {
    final hasReviews = dueReviews.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: hasReviews
                ? [AppColors.warning.withOpacity(0.08), AppColors.warning.withOpacity(0.03)]
                : [theme.colorScheme.surfaceVariant, theme.colorScheme.surfaceVariant.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: hasReviews ? AppColors.warning.withOpacity(0.12) : theme.colorScheme.onSurfaceVariant.withOpacity(0.08),
                  child: Icon(
                    hasReviews ? Icons.alarm_on : Icons.check_circle_outline,
                    color: hasReviews ? AppColors.warning : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tekrar Soruları',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        hasReviews 
                            ? 'Yanlış çözdüğün ve bugün tekrar vadesi gelen sorular.' 
                            : 'Bugün tekrar edilmesi gereken soru bulunmuyor.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (hasReviews) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${dueReviews.length} Soru Tekrar Bekliyor',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/academy-quiz', extra: 'review'),
                    icon: const Icon(Icons.replay),
                    label: const Text('Tekrarları Çöz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tekrarlar Güncel',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Icon(Icons.done_all, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeCard(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [theme.colorScheme.secondary.withOpacity(0.08), theme.colorScheme.secondary.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.12),
                  child: Icon(
                    Icons.quiz_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serbest Pratik Testi',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'İstediğin dersten istediğin sayıda pratik deneme çöz.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showPracticeConfigBottomSheet(context, ref, theme),
                    icon: const Icon(Icons.tune),
                    label: const Text('Test Başlat'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _startMistakesQuiz(context, ref),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Hata Denemesi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                      side: BorderSide(color: theme.colorScheme.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMistakesQuiz(BuildContext context, WidgetRef ref) async {
    final reviewBox = Hive.box<AcademyReviewQuestion>('academy_review_box');
    final wrongCount = reviewBox.values.where((q) => !q.isCompleted).length;

    if (wrongCount == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hata Denemesi'),
          content: const Text('Geçmişte yanlış yaptığınız ve henüz tekrar çözmediğiniz bir soru bulunmuyor. Harika gidiyorsunuz! 🎉'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Harika'),
            ),
          ],
        ),
      );
      return;
    }

    // Let's show a dialog asking how many questions they want to solve
    int count = 10;
    if (wrongCount < 10) count = wrongCount;

    final selectedCount = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempCount = count;
        return AlertDialog(
          title: const Text('Hata Denemesi Başlat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Toplam çözülmemiş $wrongCount hatanız bulunuyor.'),
              const SizedBox(height: 16),
              const Text('Çözmek istediğiniz soru sayısı:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: tempCount,
                items: [5, 10, 15, 20].where((c) => c <= wrongCount || c == 5).map((c) {
                  return DropdownMenuItem<int>(
                    value: c,
                    child: Text('$c Soru'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) tempCount = val;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempCount),
              child: const Text('Başlat'),
            ),
          ],
        );
      },
    );

    if (selectedCount == null) return;

    // Start Mistakes Quiz
    await ref.read(practiceQuizProvider.notifier).startMistakesQuiz(questionCount: selectedCount);
    if (context.mounted) {
      context.push('/academy-quiz', extra: 'practice');
    }
  }

  void _showTopicSelectionDialog({
    required BuildContext context,
    required List<String> allTopics,
    required List<String> initiallySelected,
    required Function(List<String>) onSelected,
    required ThemeData theme,
  }) {
    List<String> tempSelected = List.from(initiallySelected);
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredTopics = allTopics
                .where((t) => t.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return AlertDialog(
              title: const Text('Konuları Seçin'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Konu ara...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelected = List.from(allTopics);
                            });
                          },
                          child: const Text('Tümünü Seç'),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelected.clear();
                            });
                          },
                          child: const Text('Temizle'),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredTopics.length,
                        itemBuilder: (context, index) {
                          final topic = filteredTopics[index];
                          final isChecked = tempSelected.contains(topic);
                          return CheckboxListTile(
                            title: Text(topic, style: const TextStyle(fontSize: 13)),
                            value: isChecked,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  tempSelected.add(topic);
                                } else {
                                  tempSelected.remove(topic);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onSelected(tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPracticeConfigBottomSheet(BuildContext context, WidgetRef ref, ThemeData theme) {
    String selectedCategory = 'Karma';
    List<String> selectedTopics = [];
    int selectedCount = 10;
    
    final allQuestions = ref.read(academyQuestionsProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> topics = selectedCategory == 'Karma'
                ? []
                : (allQuestions
                    .where((q) => q.category == selectedCategory)
                    .map((q) => q.topic)
                    .where((topic) => topic.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort());

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pratik Testi Özelleştir',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ders Seçimi',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Karma', 'Tarih', 'Coğrafya', 'Vatandaşlık'].map((cat) {
                            final isSelected = selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() {
                                    selectedCategory = cat;
                                    selectedTopics.clear();
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        if (selectedCategory != 'Karma') ...[
                          const SizedBox(height: 20),
                          Text(
                            'Konu Seçimi',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _showTopicSelectionDialog(
                                context: context,
                                allTopics: topics,
                                initiallySelected: selectedTopics,
                                onSelected: (newSelection) {
                                  setModalState(() {
                                    selectedTopics = newSelection;
                                  });
                                },
                                theme: theme,
                              );
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedTopics.isEmpty
                                          ? 'Tüm Konular (Rastgele)'
                                          : selectedTopics.join(', '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'Soru Sayısı',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [5, 10, 20].map((count) {
                            final isSelected = selectedCount == count;
                            return ChoiceChip(
                              label: Text('$count Soru'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() {
                                    selectedCount = count;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: () {
                            ref.read(practiceQuizProvider.notifier).startPracticeQuiz(
                                  category: selectedCategory,
                                  topics: selectedTopics.isEmpty ? null : selectedTopics,
                                  questionCount: selectedCount,
                                );
                            Navigator.pop(context);
                            context.push('/academy-quiz', extra: 'practice');
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Testi Başlat'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPastQuestionsCard(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.primary.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  child: Icon(
                    Icons.history_edu,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Çıkmış Soruları Çöz',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Önceki sınavlarda sorulmuş gerçek KPSS Genel Kültür sorularını çöz.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showPastConfigBottomSheet(context, ref, theme),
                icon: const Icon(Icons.psychology),
                label: const Text('Çıkmış Sorular Testi Başlat'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseNotesCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [theme.colorScheme.secondary.withOpacity(0.08), theme.colorScheme.secondary.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.12),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Akademi Ders Notları',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tarih, Coğrafya ve Vatandaşlık sınav notlarını inceleyin ve çalışın.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/academy-notes'),
                icon: const Icon(Icons.chrome_reader_mode),
                label: const Text('Ders Notlarını Oku'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTrackerCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.primary.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  child: Icon(
                    Icons.assignment_turned_in_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konu Takip Matrisi 🎯',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ders notu okuma, soru çözümü ve ünite başarı analizlerini takip et.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/academy-topic-tracker'),
                icon: const Icon(Icons.analytics),
                label: const Text('Müfredat Takibini Aç'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPastConfigBottomSheet(BuildContext context, WidgetRef ref, ThemeData theme) {
    String selectedCategory = 'Karma';
    String selectedTopic = 'Tüm Konular';
    int selectedCount = 10;

    final allPastQuestions = ref.read(pastQuestionsProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> topics = selectedCategory == 'Karma'
                ? []
                : (allPastQuestions
                    .where((q) => q.category == selectedCategory)
                    .map((q) => q.topic)
                    .where((topic) => topic.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort());

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Çıkmış Sorular Testini Özelleştir',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ders Seçimi',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Karma', 'Tarih', 'Coğrafya', 'Vatandaşlık'].map((cat) {
                            final isSelected = selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() {
                                    selectedCategory = cat;
                                    selectedTopic = 'Tüm Konular';
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        if (selectedCategory != 'Karma') ...[
                          const SizedBox(height: 20),
                          Text(
                            'Konu Seçimi',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedTopic,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'Tüm Konular',
                                child: Text('Tüm Konular (Rastgele)'),
                              ),
                              ...topics.map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  )),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedTopic = val;
                                });
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'Soru Sayısı',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [5, 10, 20].map((count) {
                            final isSelected = selectedCount == count;
                            return ChoiceChip(
                              label: Text('$count Soru'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() {
                                    selectedCount = count;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: () {
                            ref.read(pastQuizProvider.notifier).startPastQuiz(
                                  category: selectedCategory,
                                  topic: selectedTopic,
                                  questionCount: selectedCount,
                                );
                            Navigator.pop(context);
                            context.push('/academy-quiz', extra: 'past');
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Testi Başlat'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsGrid(AcademyStats stats, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatGridItem('Toplam Çözülen', '${stats.totalQuestions}', Icons.question_answer_outlined, theme.colorScheme.primary, itemWidth, theme),
            _buildStatGridItem('Doğru Cevap', '${stats.totalCorrect}', Icons.check_circle_outline, AppColors.success, itemWidth, theme),
            _buildStatGridItem('Yanlış Cevap', '${stats.totalIncorrect}', Icons.cancel_outlined, AppColors.error, itemWidth, theme),
            _buildStatGridItem('Başarı Oranı', '%${stats.overallSuccessRate.toStringAsFixed(0)}', Icons.percent, AppColors.geometry, itemWidth, theme),
          ],
        );
      },
    );
  }

  Widget _buildStatGridItem(String label, String value, IconData icon, Color color, double width, ThemeData theme) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceCard(AcademyStats stats, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ders Başarı Oranları',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCategoryProgressBar('Tarih', stats.historySuccessRate, AppColors.history, theme),
            const SizedBox(height: 12),
            _buildCategoryProgressBar('Coğrafya', stats.geographySuccessRate, AppColors.geography, theme),
            const SizedBox(height: 12),
            _buildCategoryProgressBar('Vatandaşlık', stats.civicsSuccessRate, AppColors.civics, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgressBar(String name, double rate, Color color, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            Text('%${rate.toStringAsFixed(0)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: color.withOpacity(0.12),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthWeaknessCard(AcademyStats stats, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('En Güçlü Konu', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text(
                        stats.strongestTopic,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.thumb_down_alt_outlined, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('En Zayıf Konu', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text(
                        stats.weakestTopic,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChartCard(AcademyStats stats, ThemeData theme) {
    final progressData = stats.last30DaysProgress;
    final maxCount = progressData.map((d) => d.totalCount).reduce((a, b) => a > b ? a : b);
    final double yInterval = maxCount > 0 ? (maxCount / 4).ceilToDouble() : 5;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son 30 Günlük İlerleme',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxCount > 5 ? maxCount : 5).toDouble() + 1,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= progressData.length) return const SizedBox.shrink();
                          // Only show titles for every 7 days to avoid overlap
                          if (index % 7 != 0 && index != progressData.length - 1) return const SizedBox.shrink();
                          final date = progressData[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd.MM').format(date),
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval > 0 ? yInterval : 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                        reservedSize: 20,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withOpacity(0.04),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(progressData.length, (index) {
                    final day = progressData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: day.totalCount.toDouble(),
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                          rodStackItems: [
                            BarChartRodStackItem(0, day.correctCount.toDouble(), AppColors.success),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Doğru', AppColors.success),
                const SizedBox(width: 16),
                _buildLegendItem('Yanlış', theme.colorScheme.primary.withOpacity(0.2)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  void _showAcademyInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Genel Kültür Akademisi Hakkında'),
          content: const Text(
            'Bu bölüm KPSS adayları için özel olarak tasarlanmış bir genel kültür çalışma modülüdür.\n\n'
            '• Tamamen çevrimdışı (offline) çalışır.\n'
            '• Tarih, Coğrafya ve Vatandaşlık derslerinden her gün rastgele 5 yeni soru sunulur.\n'
            '• Çözdüğün sorulardan yanlış yapılanlar otomatik olarak Spaced Repetition (Aralıklı Tekrar) sistemine aktarılır (1, 3, 7, 15, 30 gün aralıklarla).\n'
            '• Ders ve konu bazlı başarı oranlarını takip edebilir, gelişimini son 30 gün grafiğinden izleyebilirsin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }
}
