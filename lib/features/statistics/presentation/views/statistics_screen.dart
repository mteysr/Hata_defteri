import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../lessons/presentation/controllers/lesson_controller.dart';
import '../../../lessons/data/models/lesson.dart';
import '../../../mistakes/presentation/controllers/mistake_controller.dart';
import '../controllers/statistics_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final mistakes = ref.watch(mistakeListProvider);
    final lessons = ref.watch(lessonListProvider);
    final theme = Theme.of(context);

    final insights = _generateInsights(stats, mistakes, lessons);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişim ve İstatistik'),
      ),
      body: mistakes.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Core Stats Summary
                  _buildPerformanceHeader(context, stats),
                  const SizedBox(height: 24),

                  // Written Analytics Insights Card (Highlight of the App)
                  _buildInsightsCard(context, insights),
                  const SizedBox(height: 24),

                  // Lesson Distribution Pie Chart
                  Text(
                    'Derslere Göre Dağılım',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildLessonPieChart(context, stats),
                  const SizedBox(height: 24),

                  // Reason Distribution Pie Chart
                  Text(
                    'Hata Nedenleri Dağılımı',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildReasonPieChart(context, stats),
                  const SizedBox(height: 24),

                  // Worst Subjects list
                  Text(
                    'En Çok Hata Yapılan Konular',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildWorstSubjectsList(context, stats),
                  const SizedBox(height: 30),
                ],
              ),
            ),
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
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Yetersiz Veri',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Grafikleri ve kişisel eksiklik analizlerini görebilmek için hata defterinize birkaç yanlış soru eklemelisiniz.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceHeader(BuildContext context, AppStatistics stats) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderItem(
            context,
            label: 'Toplam Çözülen',
            value: stats.totalSolvedReviews.toString(),
            color: theme.colorScheme.primary,
          ),
          Container(height: 40, width: 1, color: theme.dividerColor.withOpacity(0.2)),
          _buildHeaderItem(
            context,
            label: 'Doğru Oranı',
            value: '%${stats.successRate.toStringAsFixed(0)}',
            color: AppColors.success,
          ),
          Container(height: 40, width: 1, color: theme.dividerColor.withOpacity(0.2)),
          _buildHeaderItem(
            context,
            label: 'Tekrar Bekleyen',
            value: stats.dueReviewCount.toString(),
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(BuildContext context, {required String label, required String value, required Color color}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(BuildContext context, List<String> insights) {
    final theme = Theme.of(context);
    if (insights.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.7),
            theme.colorScheme.primaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Akıllı Analiz Raporu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: insights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      insights[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPieChart(BuildContext context, AppStatistics stats) {
    final theme = Theme.of(context);
    final entries = stats.lessonMistakesDistribution.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: entries.map((entry) {
                    final color = AppColors.getLessonColor(entry.key);
                    final double percentage = (entry.value / stats.totalMistakes) * 100;
                    return PieChartSectionData(
                      color: color,
                      value: entry.value.toDouble(),
                      title: '%${percentage.toStringAsFixed(0)}',
                      radius: 30,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: entries.map((entry) {
                final color = AppColors.getLessonColor(entry.key);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key} (${entry.value})',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonPieChart(BuildContext context, AppStatistics stats) {
    final theme = Theme.of(context);
    final entries = stats.reasonMistakesDistribution.entries.toList();

    final List<Color> colors = [
      AppColors.error,
      AppColors.warning,
      AppColors.info,
      AppColors.success,
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(entries.length, (idx) {
                    final entry = entries[idx];
                    final color = colors[idx % colors.length];
                    final double percentage = (entry.value / stats.totalMistakes) * 100;
                    return PieChartSectionData(
                      color: color,
                      value: entry.value.toDouble(),
                      title: '%${percentage.toStringAsFixed(0)}',
                      radius: 30,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: List.generate(entries.length, (idx) {
                final entry = entries[idx];
                final color = colors[idx % colors.length];
                final translatedReason = AppConstants.reasonTranslations[entry.key] ?? entry.key;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '$translatedReason (${entry.value})',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorstSubjectsList(BuildContext context, AppStatistics stats) {
    final theme = Theme.of(context);
    final sortedSubjects = stats.subjectMistakesDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topSubjects = sortedSubjects.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topSubjects.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final entry = topSubjects[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    radius: 12,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.value} Yanlış',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<String> _generateInsights(AppStatistics stats, List mistakes, List lessons) {
    final List<String> insights = [];

    // 1. Worst Lesson breakdown
    if (stats.mostWrongLesson != 'Yok' && stats.totalMistakes > 0) {
      final lessonCount = stats.lessonMistakesDistribution[stats.mostWrongLesson] ?? 0;
      final double lessonPercent = (lessonCount / stats.totalMistakes) * 100;
      
      // Find worst subject in that lesson
      final lessonObj = lessons.cast<Lesson?>().firstWhere((l) => l?.name == stats.mostWrongLesson, orElse: () => null);
      if (lessonObj != null) {
        final Map<String, int> subMap = {};
        final lessonMistakes = mistakes.where((m) => m.lessonId == lessonObj.id);
        for (var m in lessonMistakes) {
          subMap[m.subject] = (subMap[m.subject] ?? 0) + 1;
        }

        if (subMap.isNotEmpty) {
          final worstSub = (subMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
          final double subPercent = (worstSub.value / lessonCount) * 100;
          insights.add(
            '${stats.mostWrongLesson} yanlışlarının %${subPercent.toStringAsFixed(0)}\'si ${worstSub.key} konusunda.',
          );
        }
      }
    }

    // 2. Reason breakdown
    if (stats.reasonMistakesDistribution.isNotEmpty && stats.totalMistakes > 0) {
      final worstReasonEntry = (stats.reasonMistakesDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))).first;
      final double reasonPercent = (worstReasonEntry.value / stats.totalMistakes) * 100;
      final translatedReason = AppConstants.reasonTranslations[worstReasonEntry.key] ?? worstReasonEntry.key;
      insights.add(
        'Yanlışlarının %${reasonPercent.toStringAsFixed(0)}\'si $translatedReason kaynaklı.',
      );
    }

    // 3. Worst Book breakdown
    final Map<String, int> bookMap = {};
    for (var m in mistakes) {
      if (m.sourceBook != null && m.sourceBook!.trim().isNotEmpty) {
        bookMap[m.sourceBook!] = (bookMap[m.sourceBook!] ?? 0) + 1;
      }
    }
    if (bookMap.isNotEmpty) {
      final worstBook = (bookMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
      insights.add('En çok yanlış yaptığın kaynak kitap: ${worstBook.key}.');
    }

    // 4. Trend review performance
    if (stats.totalSolvedReviews > 0) {
      insights.add('Tekrar ettiğin soruların %${stats.successRate.toStringAsFixed(0)}\'sini bugün doğru çözdün.');
    } else {
      insights.add('Tekrar çözümlerine başlayarak kişisel gelişim analizini tetikleyin.');
    }

    return insights;
  }
}
