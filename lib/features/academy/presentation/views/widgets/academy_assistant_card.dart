import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../domain/models/academy_answer_history.dart';
import '../../../domain/models/academy_review_question.dart';
import '../../../domain/models/academy_note_booklet.dart';
import '../../../domain/models/academy_question.dart';
import '../../controllers/academy_controller.dart';
import '../../../../../core/constants/app_colors.dart';

class AcademyAssistantCard extends ConsumerStatefulWidget {
  const AcademyAssistantCard({super.key});

  @override
  ConsumerState<AcademyAssistantCard> createState() => _AcademyAssistantCardState();
}

class _AcademyAssistantCardState extends ConsumerState<AcademyAssistantCard> {
  int _activeWeakTopicIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyBox = Hive.box<AcademyAnswerHistory>('academy_history_box');
    final logs = historyBox.values.toList();

    // 1. Group attempts by category and topic
    final Map<String, _TopicAttempt> topicMetrics = {};

    for (final log in logs) {
      final key = '${log.category}##${log.topic}';
      if (!topicMetrics.containsKey(key)) {
        topicMetrics[key] = _TopicAttempt(category: log.category, topic: log.topic);
      }
      topicMetrics[key]!.addAttempt(log.isCorrect);
    }

    // 2. Filter topics with at least 1 attempt and success rate < 80%
    final weakTopics = topicMetrics.values.where((t) {
      return t.attemptCount >= 1 && t.successRate < 80.0;
    }).toList();

    // Sort weak topics: lowest success rate first
    weakTopics.sort((a, b) => a.successRate.compareTo(b.successRate));

    // Boundary check for index
    if (weakTopics.isNotEmpty && _activeWeakTopicIndex >= weakTopics.length) {
      _activeWeakTopicIndex = 0;
    }

    // 3. Render state based on performance
    if (logs.isEmpty) {
      // Welcome state
      return _buildCard(
        context: context,
        theme: theme,
        title: '🤖 Akıllı Çalışma Asistanı',
        message: 'Akademiye hoş geldiniz! Başarı analizlerinizi yapabilmem ve size özel tavsiyeler sunabilmem için öncelikle pratik veya çıkmış testler çözmeye başlayabilirsiniz.',
        icon: Icons.psychology_outlined,
        buttonText: 'İlk Testi Çöz',
        showNextButton: false,
        onTap: () => _showQuickStartMenu(context, ref, theme),
      );
    }

    if (weakTopics.isEmpty) {
      // Good performance state
      final double overallRate = (logs.where((l) => l.isCorrect).length / logs.length) * 100;
      return _buildCard(
        context: context,
        theme: theme,
        title: '🤖 Akıllı Çalışma Asistanı',
        message: 'Harika gidiyorsunuz! Tüm konulardaki genel başarı oranınız %${overallRate.toStringAsFixed(0)}. Bilgilerinizi taze tutmak için yeni bir pratik test çözebilirsiniz.',
        icon: Icons.insights_outlined,
        buttonText: 'Pratik Testi Çöz',
        showNextButton: false,
        onTap: () => _showQuickStartMenu(context, ref, theme),
      );
    }

    // Deficiency state: select the active weak topic
    final weakest = weakTopics[_activeWeakTopicIndex];

    return _buildCard(
      context: context,
      theme: theme,
      title: '🤖 Çalışma Asistanı (${_activeWeakTopicIndex + 1}/${weakTopics.length})',
      message: '🚨 ${weakest.category} - ${weakest.topic} konusundaki başarı oranınız %${weakest.successRate.toStringAsFixed(0)} (${weakest.attemptCount} soruda). Bu konuda biraz zorlandığınızı fark ettim. Eksikliği hemen giderelim!',
      icon: Icons.assistant_outlined,
      buttonText: 'Eksikliği Gider',
      isWarning: true,
      showNextButton: weakTopics.length > 1,
      onNextTap: () {
        setState(() {
          _activeWeakTopicIndex = (_activeWeakTopicIndex + 1) % weakTopics.length;
        });
      },
      onTap: () => _showInterventionSheet(context, ref, theme, weakest.category, weakest.topic),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String message,
    required IconData icon,
    required String buttonText,
    required VoidCallback onTap,
    bool isWarning = false,
    bool showNextButton = false,
    VoidCallback? onNextTap,
  }) {
    final gradientColors = isWarning
        ? [theme.colorScheme.error.withOpacity(0.08), theme.colorScheme.error.withOpacity(0.02)]
        : [theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.primary.withOpacity(0.02)];

    final accentColor = isWarning ? theme.colorScheme.error : theme.colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: accentColor.withOpacity(0.12),
                      child: Icon(
                        icon,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isWarning ? theme.colorScheme.error : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (showNextButton)
                  IconButton(
                    icon: Icon(Icons.navigate_next, color: accentColor),
                    onPressed: onNextTap,
                    tooltip: 'Diğer Tavsiye',
                    style: IconButton.styleFrom(
                      backgroundColor: accentColor.withOpacity(0.08),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.3,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isWarning ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickStartMenu(BuildContext context, WidgetRef ref, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Akıllı Başlangıç',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Bilgilerinizi taze tutmak için aşağıdaki adımlardan birini seçin:',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.psychology, color: theme.colorScheme.primary),
                ),
                title: const Text('Serbest Pratik Testi Çöz', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('İstediğiniz ders ve konudan yeni test başlatın.'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/academy');
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chrome_reader_mode, color: theme.colorScheme.secondary),
                ),
                title: const Text('Ders Notlarını Oku', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tarih veya Coğrafya notlarını okuyarak tekrar yapın.'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/academy-notes');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInterventionSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String category,
    String topic,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eksikliği Giderme İstasyonu',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '$category - $topic',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Option 1: Read Notes
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chrome_reader_mode, color: theme.colorScheme.secondary),
                ),
                title: const Text('Ders Notunu Oku', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Konu anlatım notlarında bu ünitenin sayfalarına gidin.'),
                onTap: () {
                  Navigator.pop(context);
                  final bookletIndex = kAcademyNoteBooklets.indexWhere((b) => b.category == category);
                  if (bookletIndex != -1) {
                    final booklet = kAcademyNoteBooklets[bookletIndex];
                    final String query = topic.split(' ').first;
                    final searchBooklet = booklet.copyWith(initialSearchQuery: query);
                    context.push('/academy-notes-viewer', extra: searchBooklet);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bu ders için henüz ders notu eklenmemiş.')),
                    );
                  }
                },
              ),
              const Divider(),

              // Option 2: Solve Wrong Questions
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cancel_outlined, color: AppColors.error),
                ),
                title: const Text('Yanlış Sorularımı Çöz', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Bu konudan geçmişte yaptığınız hataları tekrar çözün.'),
                onTap: () async {
                  Navigator.pop(context);
                  
                  final reviewBox = Hive.box<AcademyReviewQuestion>('academy_review_box');
                  final wrongIds = reviewBox.values
                      .where((q) => !q.isCompleted && q.category == category && q.topic == topic)
                      .map((q) => q.questionId)
                      .toSet();
                      
                  if (wrongIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bu konudan geçmişte yaptığınız çözülmemiş bir hata bulunmuyor. Yeni konu testi çözebilirsiniz!'),
                      ),
                    );
                    return;
                  }

                  final allQuestions = await ref.read(academyQuestionsProvider.future);
                  final wrongQuestions = allQuestions.where((q) => wrongIds.contains(q.id)).toList();

                  if (wrongQuestions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hata sorularının detayları yüklenemedi.')),
                    );
                    return;
                  }

                  ref.read(practiceQuizProvider.notifier).startCustomQuiz(wrongQuestions);
                  context.push('/academy-quiz', extra: 'practice');
                },
              ),
              const Divider(),

              // Option 3: Solve New Practice Quiz
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.success),
                ),
                title: const Text('Yeni Konu Testi Çöz', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Konudan yeni hazırlanmış 10 soruluk bir test başlatın.'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(practiceQuizProvider.notifier).startPracticeQuiz(
                    category: category,
                    topics: [topic],
                    questionCount: 10,
                  );
                  context.push('/academy-quiz', extra: 'practice');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopicAttempt {
  final String category;
  final String topic;
  int _totalAttempts = 0;
  int _correctAttempts = 0;

  _TopicAttempt({required this.category, required this.topic});

  void addAttempt(bool isCorrect) {
    _totalAttempts++;
    if (isCorrect) {
      _correctAttempts++;
    }
  }

  int get attemptCount => _totalAttempts;
  double get successRate => _totalAttempts > 0 ? (_correctAttempts / _totalAttempts) * 100 : 0.0;
}
