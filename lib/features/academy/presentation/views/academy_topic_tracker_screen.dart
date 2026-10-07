import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../lessons/data/models/lesson.dart';
import '../../domain/models/academy_answer_history.dart';
import '../../../../core/constants/app_colors.dart';

class AcademyTopicTrackerScreen extends ConsumerStatefulWidget {
  const AcademyTopicTrackerScreen({super.key});

  @override
  ConsumerState<AcademyTopicTrackerScreen> createState() => _AcademyTopicTrackerScreenState();
}

class _AcademyTopicTrackerScreenState extends ConsumerState<AcademyTopicTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Box _settingsBox = Hive.box('academy_settings_box');

  // Mapped subjects list loaded dynamically from Hive lessons_box
  Map<String, List<String>> _subjectTopics = {
    'Tarih': [
      'İslamiyet Öncesi Türk Tarihi',
      'Türk İslam Tarihi',
      'Osmanlı Tarihi',
      'Atatürk İlkeleri ve İnkılap Tarihi',
      'Çağdaş Türk ve Dünya Tarihi',
    ],
    'Coğrafya': [
      'Türkiye\'nin Coğrafi Konumu',
      'Türkiye\'de Yerşekilleri - Dağlar',
      'Türkiye\'nin İklimi',
      'Türkiye\'nin Beşeri Coğrafyası',
      'Türkiye\'nin Ekonomik Coğrafyası',
    ],
    'Vatandaşlık': [
      'Hukukun Temel Kavramları',
      'Anayasal Gelişmeler',
      'Temel Hak ve Ödevler',
      'Devletin Temel Organları',
      'İdare Hukuku',
    ],
  };

  List<String> _readNotes = [];
  List<String> _solvedQuestions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrackerData();
    _loadDynamicSubjectTopics();
  }

  void _loadDynamicSubjectTopics() {
    try {
      final lessonsBox = Hive.box<Lesson>('lessons_box');
      final newMap = <String, List<String>>{};
      for (final key in ['Tarih', 'Coğrafya', 'Vatandaşlık']) {
        final lesson = lessonsBox.values.where((l) => l.name == key).firstOrNull;
        if (lesson != null && lesson.subjects.isNotEmpty) {
          newMap[key] = List<String>.from(lesson.subjects);
        } else {
          newMap[key] = _subjectTopics[key]!;
        }
      }
      setState(() {
        _subjectTopics = newMap;
      });
    } catch (e) {
      // Fallback
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTrackerData() {
    final rawNotes = _settingsBox.get('topic_notes_read', defaultValue: <dynamic>[]);
    final rawSolved = _settingsBox.get('topic_questions_solved', defaultValue: <dynamic>[]);

    setState(() {
      _readNotes = List<String>.from(rawNotes);
      _solvedQuestions = List<String>.from(rawSolved);
    });
  }

  Future<void> _toggleNoteRead(String topic, bool checked) async {
    final updatedList = List<String>.from(_readNotes);
    if (checked) {
      if (!updatedList.contains(topic)) updatedList.add(topic);
    } else {
      updatedList.remove(topic);
    }
    await _settingsBox.put('topic_notes_read', updatedList);
    setState(() {
      _readNotes = updatedList;
    });
  }

  Future<void> _toggleQuestionSolved(String topic, bool checked) async {
    final updatedList = List<String>.from(_solvedQuestions);
    if (checked) {
      if (!updatedList.contains(topic)) updatedList.add(topic);
    } else {
      updatedList.remove(topic);
    }
    await _settingsBox.put('topic_questions_solved', updatedList);
    setState(() {
      _solvedQuestions = updatedList;
    });
  }

  // Calculate dynamic success rate based on solved attempts in history logs
  Map<String, dynamic> _calculateTopicStats(String topic) {
    try {
      final historyBox = Hive.box<AcademyAnswerHistory>('academy_history_box');
      final attempts = historyBox.values.where((h) => h.topic == topic).toList();

      if (attempts.isEmpty) {
        return {'rate': -1.0, 'total': 0, 'correct': 0};
      }

      final correctCount = attempts.where((h) => h.isCorrect).length;
      final double rate = (correctCount / attempts.length) * 100;

      return {'rate': rate, 'total': attempts.length, 'correct': correctCount};
    } catch (e) {
      return {'rate': -1.0, 'total': 0, 'correct': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic stats summaries for headers
    final totalTopics = _subjectTopics.values.fold<int>(0, (sum, list) => sum + list.length);
    final readNotesCount = _readNotes.length;
    final solvedQuestionsCount = _solvedQuestions.length;
    final progressPercentage = totalTopics > 0 
        ? ((readNotesCount + solvedQuestionsCount) / (totalTopics * 2) * 100).toInt()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KPSS Konu Takip Matrisi'),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Tarih', icon: Icon(Icons.history)),
            Tab(text: 'Coğrafya', icon: Icon(Icons.public)),
            Tab(text: 'Vatandaşlık', icon: Icon(Icons.gavel)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Premium Header Statistics Dashboard Box
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.primary.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Müfredat İlerleme Durumu',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '%$progressPercentage',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(
                      context,
                      icon: Icons.menu_book,
                      title: 'Okunan Notlar',
                      value: '$readNotesCount / $totalTopics',
                      color: Colors.blue,
                    ),
                    Container(width: 1, height: 32, color: theme.dividerColor.withOpacity(0.2)),
                    _buildSummaryStat(
                      context,
                      icon: Icons.edit_note,
                      title: 'Çözülen Konular',
                      value: '$solvedQuestionsCount / $totalTopics',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Expanded Subject Topics Tab Pages
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopicsList('Tarih'),
                _buildTopicsList('Coğrafya'),
                _buildTopicsList('Vatandaşlık'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildTopicsList(String subject) {
    final topics = _subjectTopics[subject] ?? [];
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        final isRead = _readNotes.contains(topic);
        final isSolved = _solvedQuestions.contains(topic);
        final stats = _calculateTopicStats(topic);
        
        final double rate = stats['rate'] as double;
        final int total = stats['total'] as int;
        final int correct = stats['correct'] as int;

        Color rateColor = Colors.grey;
        if (rate >= 80) rateColor = AppColors.success;
        else if (rate >= 50) rateColor = Colors.orange;
        else if (rate >= 0) rateColor = AppColors.error;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic Name Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        topic,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Success Rate Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: rateColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rateColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        rate >= 0 ? '%${rate.toStringAsFixed(0)} Başarı' : 'Çözülmedi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: rate >= 0 ? rateColor : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Solve count subtext
                if (rate >= 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'İstatistik: $correct Doğru / $total Soru Çözüldü',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Checklist Toggles Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _toggleNoteRead(topic, !isRead),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isRead ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isRead ? Colors.blue : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Not Okundu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isRead ? FontWeight.bold : FontWeight.normal,
                                    color: isRead ? Colors.blue : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _toggleQuestionSolved(topic, !isSolved),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isSolved ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isSolved ? Colors.orange : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Soru Çözüldü',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSolved ? FontWeight.bold : FontWeight.normal,
                                    color: isSolved ? Colors.orange : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
