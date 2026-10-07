import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/study_timer_controller.dart';
import '../../controllers/academy_stats_provider.dart';

class StudyTimerSection extends ConsumerStatefulWidget {
  const StudyTimerSection({super.key});

  @override
  ConsumerState<StudyTimerSection> createState() => _StudyTimerSectionState();
}

class _StudyTimerSectionState extends ConsumerState<StudyTimerSection> {
  final TextEditingController _topicController = TextEditingController(text: 'Genel Tekrar');

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(studyTimerProvider);
    final timerNotifier = ref.read(studyTimerProvider.notifier);
    final theme = Theme.of(context);

    Color themeColor = theme.colorScheme.primary;
    if (timerState.category == 'Coğrafya') themeColor = Colors.orange;
    if (timerState.category == 'Vatandaşlık') themeColor = Colors.teal;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Header
            Row(
              children: [
                Icon(Icons.timer_outlined, color: themeColor),
                const SizedBox(width: 8),
                Text(
                  'Çalışma Kronometresi (Pomodoro)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode Selector
            Row(
              children: [
                _buildModeButton(ref, 'pomodoro', 'Pomodoro', timerState.mode == 'pomodoro', themeColor),
                const SizedBox(width: 8),
                _buildModeButton(ref, 'shortBreak', 'Kısa Ara', timerState.mode == 'shortBreak', themeColor),
                const SizedBox(width: 8),
                _buildModeButton(ref, 'longBreak', 'Uzun Ara', timerState.mode == 'longBreak', themeColor),
              ],
            ),
            const SizedBox(height: 16),

            // Category & Topic Pickers (Only enabled if not running or in pomodoro)
            if (timerState.mode == 'pomodoro') ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: timerState.category,
                      decoration: InputDecoration(
                        labelText: 'Ders',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Tarih', child: Text('Tarih')),
                        DropdownMenuItem(value: 'Coğrafya', child: Text('Coğrafya')),
                        DropdownMenuItem(value: 'Vatandaşlık', child: Text('Vatandaşlık')),
                      ],
                      onChanged: timerState.isRunning
                          ? null
                          : (val) {
                              if (val != null) {
                                timerNotifier.setCategory(val);
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _topicController,
                      enabled: !timerState.isRunning,
                      decoration: InputDecoration(
                        labelText: 'Konu Başlığı',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        timerNotifier.setTopic(val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Radial Countdown Timer
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: CircularProgressIndicator(
                      value: timerState.totalSeconds > 0
                          ? timerState.remainingSeconds / timerState.totalSeconds
                          : 0.0,
                      strokeWidth: 10,
                      color: themeColor,
                      backgroundColor: themeColor.withOpacity(0.12),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(timerState.remainingSeconds),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timerState.isRunning ? 'Odaklanma Süresi' : 'Hazır',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Controls Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button
                IconButton.filledTonal(
                  icon: const Icon(Icons.replay),
                  iconSize: 24,
                  onPressed: timerNotifier.reset,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 16),

                // Play / Pause Button
                IconButton.filled(
                  icon: Icon(timerState.isRunning ? Icons.pause : Icons.play_arrow),
                  iconSize: 32,
                  onPressed: timerState.isRunning ? timerNotifier.pause : timerNotifier.start,
                  style: IconButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(width: 16),

                // Skip / Manual Finish Button (Only shown in Pomodoro Mode to log session easily)
                if (timerState.mode == 'pomodoro')
                  IconButton.filledTonal(
                    icon: const Icon(Icons.check_circle_outline),
                    iconSize: 24,
                    onPressed: () => _confirmFinishSession(context, ref, timerState),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    WidgetRef ref,
    String mode,
    String label,
    bool isActive,
    Color activeColor,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => ref.read(studyTimerProvider.notifier).setMode(mode),
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? activeColor : Colors.transparent,
          foregroundColor: isActive ? Colors.white : activeColor,
          side: BorderSide(color: activeColor),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  void _confirmFinishSession(
    BuildContext context,
    WidgetRef ref,
    StudyTimerState timerState,
  ) {
    final int completedMinutes = (timerState.totalSeconds - timerState.remainingSeconds) ~/ 60;
    if (completedMinutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çalışmayı kaydetmek için en az 1 dakika tamamlamalısınız.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Çalışmayı Tamamla'),
          content: Text('$completedMinutes dakikalık ${timerState.category} çalışmasını kaydetmek istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final notifier = ref.read(studyTimerProvider.notifier);
                await notifier.logStudySession(
                  category: timerState.category,
                  topic: timerState.topic,
                  durationMinutes: completedMinutes,
                );
                
                // Reset timer
                notifier.reset();
                
                // Invalidate stats to refresh charts
                ref.invalidate(academyStatsProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$completedMinutes dakikalık çalışma kaydedildi. Harika gidiyorsun! 🎉')),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}
