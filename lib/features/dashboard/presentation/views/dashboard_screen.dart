import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../lessons/presentation/controllers/lesson_controller.dart';
import '../../../mistakes/presentation/controllers/mistake_controller.dart';
import '../../../statistics/presentation/controllers/statistics_provider.dart';
import '../../../academy/presentation/views/widgets/academy_flashcard_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final lessons = ref.watch(lessonListProvider);
    final mistakes = ref.watch(mistakeListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final recentMistakes = mistakes.take(4).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hata Defteri',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Kişisel Çalışma Analizi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              stats.dueReviewCount > 0 ? Icons.notification_important : Icons.notifications_none,
              color: stats.dueReviewCount > 0 ? AppColors.warning : null,
            ),
            onPressed: () => context.go('/review'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome & Streak Banner
              _buildStreakBanner(context, stats),
              const SizedBox(height: 20),

              // Summary Stats Grid
              _buildSummaryGrid(context, stats),
              const SizedBox(height: 20),

              // Günün Hap Bilgileri (Ezber Kartları)
              const AcademyFlashcardCard(),
              const SizedBox(height: 20),

              // 7 Days Chart Card
              _buildWeeklyChartCard(context, stats),
              const SizedBox(height: 20),

              // Worst performing Areas Card
              _buildWeakAreasCard(context, stats),
              const SizedBox(height: 20),

              // Recent Mistakes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Son Eklenen Yanlışlar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/mistakes'),
                    child: const Text('Tümünü Gör'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recentMistakes.isEmpty)
                _buildEmptyRecentCard(context)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentMistakes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = recentMistakes[index];
                    final lesson = lessons.firstWhere(
                      (l) => l.id == item.lessonId,
                      orElse: () => lessons.first,
                    );
                    return _buildRecentMistakeCard(context, item, lesson);
                  },
                ),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-mistake'),
        tooltip: 'Yeni Yanlış Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStreakBanner(BuildContext context, AppStatistics stats) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '🔥',
              style: TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.currentStreak > 0
                      ? '${stats.currentStreak} Günlük Çalışma Serisi!'
                      : 'İlk Soru Tekrarını Yap!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  stats.currentStreak > 0
                      ? 'Harika gidiyorsun, seriyi bozma!'
                      : 'Hatalarını tekrar ederek öğrenmeye başla.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, AppStatistics stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              context,
              width: width,
              title: 'Toplam Yanlış',
              value: stats.totalMistakes.toString(),
              icon: Icons.error_outline,
              color: AppColors.error,
            ),
            _buildStatCard(
              context,
              width: width,
              title: 'Bugün Tekrar',
              value: stats.dueReviewCount.toString(),
              icon: Icons.alarm,
              color: AppColors.warning,
              onTap: () => context.go('/review'),
            ),
            _buildStatCard(
              context,
              width: width,
              title: 'Toplam Ders',
              value: stats.totalLessonsCount.toString(),
              icon: Icons.book,
              color: AppColors.info,
            ),
            _buildStatCard(
              context,
              width: width,
              title: 'Çözülen Tekrar',
              value: stats.totalSolvedReviews.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChartCard(BuildContext context, AppStatistics stats) {
    final theme = Theme.of(context);
    final dataPoints = stats.last7DaysMistakes.entries.toList();

    // Find max value for scaling y-axis
    double maxVal = 5.0;
    for (var entry in dataPoints) {
      if (entry.value > maxVal) {
        maxVal = entry.value.toDouble();
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Haftalık Eklenen Soru Grafiği',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal + 1,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.primaryContainer,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} Soru',
                          TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < dataPoints.length) {
                            final date = dataPoints[idx].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('dd.MM').format(date),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(dataPoints.length, (idx) {
                    final item = dataPoints[idx];
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: item.value.toDouble(),
                          color: theme.colorScheme.primary,
                          width: 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakAreasCard(BuildContext context, AppStatistics stats) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Çok Hata Yapılan Konumlar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildWeakIndicator(
                    context,
                    label: 'En Çok Yanlış Yapılan Ders',
                    value: stats.mostWrongLesson,
                    color: stats.mostWrongLessonColor,
                    icon: Icons.menu_book,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildWeakIndicator(
                    context,
                    label: 'En Çok Yanlış Yapılan Konu',
                    value: stats.mostWrongSubject,
                    color: theme.colorScheme.secondary,
                    icon: Icons.assignment_late,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakIndicator(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecentCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.post_add,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz kayıt eklemediniz.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'FAB butonuna tıklayarak ilk yanlış sorunuzu ekleyin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMistakeCard(BuildContext context, mistake, lesson) {
    final theme = Theme.of(context);
    final lessonColor = Color(lesson.colorValue);
    final createdDateStr = DateFormat('dd MMM yyyy').format(mistake.createdAt);

    return InkWell(
      onTap: () => context.push('/mistake-detail/${mistake.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            // Preview Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: () {
                  final file = File(mistake.questionImageFile);
                  if (mistake.questionImageFile.isEmpty || !file.isAbsolute || !file.existsSync()) {
                    return Container(
                      color: lessonColor.withOpacity(0.2),
                      child: Icon(Icons.image_not_supported, color: lessonColor),
                    );
                  }
                  return Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: lessonColor.withOpacity(0.2),
                        child: Icon(Icons.image_not_supported, color: lessonColor),
                      );
                    },
                  );
                }(),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: lessonColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lesson.name,
                          style: TextStyle(
                            color: lessonColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        createdDateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mistake.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (mistake.sourceBook != null && mistake.sourceBook!.isNotEmpty)
                    Text(
                      mistake.sourceBook!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Difficulty Badge
            _buildDifficultyChip(context, mistake.difficulty),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(BuildContext context, String difficulty) {
    final theme = Theme.of(context);
    Color color;
    switch (difficulty) {
      case 'EASY':
        color = AppColors.success;
        break;
      case 'MEDIUM':
        color = AppColors.warning;
        break;
      case 'HARD':
        color = AppColors.error;
        break;
      default:
        color = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppConstants.difficultyTranslations[difficulty] ?? difficulty,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
