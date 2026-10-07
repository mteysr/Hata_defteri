import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';

class AcademyResultScreen extends StatelessWidget {
  final int total;
  final int correct;
  final int incorrect;
  final Map<String, double> categoryStats;

  const AcademyResultScreen({
    super.key,
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.categoryStats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successRate = total > 0 ? (correct / total) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sonucu'),
        automaticallyImplyLeading: false, // Disallow back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SECTION 1: CIRCULAR SCORE METER ---
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.cardTheme.color,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: successRate / 100,
                          strokeWidth: 10,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          color: successRate >= 70
                              ? AppColors.success
                              : (successRate >= 40 ? AppColors.warning : AppColors.error),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '%${successRate.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: successRate >= 70
                                  ? AppColors.success
                                  : (successRate >= 40 ? AppColors.warning : AppColors.error),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Başarı Oranı',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- SECTION 2: GRID OF STATS ---
              Row(
                children: [
                  Expanded(
                    child: _buildStatItemCard(
                      label: 'Doğru',
                      value: '$correct',
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItemCard(
                      label: 'Yanlış',
                      value: '$incorrect',
                      color: AppColors.error,
                      icon: Icons.cancel_outlined,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- SECTION 3: CATEGORY STATS ---
              Text(
                'Ders Performansları',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: categoryStats.entries.map((entry) {
                      final category = entry.key;
                      final rate = entry.value;
                      final color = _getCategoryColor(category);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(category, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
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
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- SECTION 4: SPACING SYSTEM ALIGNMENT ALERT ---
              if (incorrect > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_on, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Yanlış yaptığın $incorrect soru otomatik olarak Akademi "Tekrar Soruları" listesine eklendi. Aralıklı tekrar sistemiyle onları tekrar çözeceksin.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Return Button
              FilledButton.icon(
                onPressed: () {
                  context.replace('/academy');
                },
                icon: const Icon(Icons.school),
                label: const Text('Akademiye Dön'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItemCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (category == 'Tarih') return AppColors.history;
    if (category == 'Coğrafya') return AppColors.geography;
    if (category == 'Vatandaşlık') return AppColors.civics;
    return AppColors.lightPrimary;
  }
}
