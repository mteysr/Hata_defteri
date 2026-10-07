import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../lessons/presentation/controllers/lesson_controller.dart';
import '../controllers/mistake_controller.dart';
import '../../domain/models/mistake.dart';

class MistakeDetailScreen extends ConsumerWidget {
  final String mistakeId;

  const MistakeDetailScreen({super.key, required this.mistakeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakes = ref.watch(mistakeListProvider);
    final lessons = ref.watch(lessonListProvider);
    final theme = Theme.of(context);

    // Safety check if mistake is deleted and screen is popping
    final mistakeIndex = mistakes.indexWhere((m) => m.id == mistakeId);
    if (mistakeIndex == -1) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mistake = mistakes[mistakeIndex];

    final lesson = lessons.firstWhere(
      (l) => l.id == mistake.lessonId,
      orElse: () => lessons.first,
    );
    final lessonColor = Color(lesson.colorValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soru Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/add-mistake', extra: mistake.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmDialog(context, ref, mistake.id),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Image
            Text(
              mistake.tags.contains('Akademi') ? 'Soru Metni' : 'Soru Fotoğrafı',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInteractivePhotoCard(context, mistake.questionImageFile, mistake),
            const SizedBox(height: 20),

            // Lesson & Subject Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: lessonColor.withOpacity(0.15),
                  radius: 20,
                  child: Icon(
                    AppConstants.getIconData(lesson.iconCodePoint),
                    color: lessonColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: lessonColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        mistake.subject,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metadata Grid
            _buildMetadataGrid(context, mistake),
            const SizedBox(height: 20),

            // Difficulty & Reason
            Row(
              children: [
                Expanded(
                  child: _buildBadgeCard(
                    context,
                    title: 'Zorluk Derecesi',
                    value: AppConstants.difficultyTranslations[mistake.difficulty] ?? mistake.difficulty,
                    color: _getDifficultyColor(mistake.difficulty),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBadgeCard(
                    context,
                    title: 'Hata Nedeni',
                    value: AppConstants.reasonTranslations[mistake.reason] ?? mistake.reason,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Spaced Repetition Progress Card
            _buildRepetitionProgressCard(context, mistake),
            const SizedBox(height: 20),

            // Correct Answer Option Card
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
              if (mistake.tags.contains('Akademi')) ...[
                Text(
                  'Cevap & Açıklama',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.15)),
                  ),
                  child: Text(
                    (mistake.note!.contains('///')) 
                        ? mistake.note!.split('///')[1].trim()
                        : mistake.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ] else ...[
                Text(
                  'Çalışma Notları',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                  ),
                  child: Text(
                    mistake.note!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Tags
            if (mistake.tags.isNotEmpty) ...[
              Text(
                'Etiketler',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: mistake.tags.map((tag) {
                  return Chip(
                    label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Solution Image
            if (mistake.solutionImageFile != null) ...[
              Text(
                'Çözüm / İpucu Fotoğrafı',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInteractivePhotoCard(context, mistake.solutionImageFile!),
              const SizedBox(height: 20),
            ],

            // Attempt History
            _buildAttemptHistoryCard(context, mistake),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractivePhotoCard(BuildContext context, String imagePath, [Mistake? mistake]) {
    final file = File(imagePath);
    final hasFile = imagePath.isNotEmpty && File(imagePath).isAbsolute && file.existsSync();

    if (!hasFile && mistake != null && mistake.tags.contains('Akademi')) {
      final parts = (mistake.note ?? '').split('///');
      final questionText = parts[0].trim();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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

    return InkWell(
      onTap: hasFile
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _ZoomableImageScreen(imagePath: imagePath),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: hasFile
              ? Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    );
                  },
                )
              : Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMetadataGrid(BuildContext context, mistake) {
    final theme = Theme.of(context);
    final items = <Widget>[];

    if (mistake.sourceBook != null) {
      items.add(_buildMetadataItem(context, 'Kaynak Kitap', mistake.sourceBook!));
    }
    if (mistake.mockExamName != null) {
      items.add(_buildMetadataItem(context, 'Deneme Sınavı', mistake.mockExamName!));
    }
    if (mistake.testName != null) {
      items.add(_buildMetadataItem(context, 'Test Adı / No', mistake.testName!));
    }
    if (mistake.pageNumber != null) {
      items.add(_buildMetadataItem(context, 'Sayfa No', mistake.pageNumber!.toString()));
    }
    if (mistake.questionNumber != null) {
      items.add(_buildMetadataItem(context, 'Soru No', mistake.questionNumber!.toString()));
    }

    if (items.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index < items.length - 1) const Divider(height: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMetadataItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(BuildContext context, {required String title, required String value, required Color color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepetitionProgressCard(BuildContext context, mistake) {
    final theme = Theme.of(context);
    final stage = mistake.reviewStage;
    final totalStages = AppConstants.reviewIntervals.length;
    final progress = stage / totalStages;
    final isCompleted = mistake.isCompleted;

    final nextReviewStr = isCompleted
        ? 'Tamamlandı'
        : DateFormat('dd.MM.yyyy').format(mistake.nextReviewAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tekrar Aşaması',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  isCompleted ? 'Öğrenildi' : 'Aşama $stage / $totalStages',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.success : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              color: isCompleted ? AppColors.success : theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bir Sonraki Tekrar:',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  nextReviewStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.success : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptHistoryCard(BuildContext context, mistake) {
    final theme = Theme.of(context);
    final List attempts = mistake.reviewAttempts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tekrar Geçmişi',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (attempts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Henüz tekrar yapılmadı.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attempts.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final attempt = attempts[index];
                  final dateStr = DateFormat('dd.MM.yyyy - HH:mm').format(attempt.attemptedAt);
                  final isSuccess = attempt.isCorrect;

                  return Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.cancel,
                        color: isSuccess ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSuccess ? 'Doğru Çözüldü' : 'Yanlış Çözüldü',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Aşama: ${attempt.stageBefore} ➜ ${attempt.stageAfter}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'EASY':
        return AppColors.success;
      case 'MEDIUM':
        return AppColors.warning;
      case 'HARD':
        return AppColors.error;
      default:
        return AppColors.lightPrimary;
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Soruyu Sil'),
          content: const Text('Bu yanlış soruyu ve ilişkili tüm fotoğrafları kalıcı olarak silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(mistakeListProvider.notifier).deleteMistake(id);
                Navigator.pop(context); // close dialog
                context.pop(); // pop details screen back to list
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }
}

// Fullscreen Pinch-to-zoom Screen
class _ZoomableImageScreen extends StatelessWidget {
  final String imagePath;

  const _ZoomableImageScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported, size: 64, color: Colors.white);
            },
          ),
        ),
      ),
    );
  }
}
