import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../../features/lessons/data/models/lesson.dart';
import '../../features/mistakes/domain/models/mistake.dart';
import '../../features/mistakes/domain/models/review_attempt.dart';
import '../../features/academy/domain/models/academy_review_question.dart';
import '../../features/academy/domain/models/academy_answer_history.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  Future<void> init() async {
    await Hive.initFlutter();

    // Register Hive Type Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LessonAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MistakeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ReviewAttemptAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AcademyReviewQuestionAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AcademyAnswerHistoryAdapter());
    }

    // Open Boxes
    await Hive.openBox(AppConstants.settingsBoxName);
    final lessonsBox = await Hive.openBox<Lesson>(AppConstants.lessonsBoxName);
    await Hive.openBox<Mistake>(AppConstants.mistakesBoxName);
    
    // Academy Boxes
    await Hive.openBox('academy_settings_box');
    await Hive.openBox<AcademyReviewQuestion>('academy_review_box');
    await Hive.openBox<AcademyAnswerHistory>('academy_history_box');

    // Populate default lessons if database is empty
    if (lessonsBox.isEmpty) {
      await _populateDefaultLessons(lessonsBox);
    }

    // Synchronize subjects to match Academy tracker topics
    await _syncLessonSubjects(lessonsBox);
  }

  Future<void> _populateDefaultLessons(Box<Lesson> box) async {
    final defaultLessons = [
      Lesson(
        id: const Uuid().v4(),
        name: 'Matematik',
        colorValue: AppColors.math.value,
        iconCodePoint: Icons.functions.codePoint,
        subjects: [
          'Problemler',
          'Fonksiyonlar',
          'Kümeler',
          'Sayı Basamakları',
          'Permütasyon',
          'Kombinasyon',
          'Olasılık',
          'Logaritma',
          'Limit',
          'Türev',
          'İntegral',
          'Trigonometri',
        ],
      ),
      Lesson(
        id: const Uuid().v4(),
        name: 'Türkçe',
        colorValue: AppColors.turkish.value,
        iconCodePoint: Icons.translate.codePoint,
        subjects: [
          'Paragraf',
          'Dil Bilgisi',
          'Cümlede Anlam',
          'Sözcükte Anlam',
          'Yazım Kuralları',
          'Noktalama İşaretleri',
        ],
      ),
      Lesson(
        id: const Uuid().v4(),
        name: 'Tarih',
        colorValue: AppColors.history.value,
        iconCodePoint: Icons.history.codePoint,
        subjects: [
          'İslamiyet Öncesi Türk Tarihi',
          'Türk İslam Tarihi',
          'Osmanlı Tarihi',
          'Atatürk İlkeleri ve İnkılap Tarihi',
          'Çağdaş Türk ve Dünya Tarihi',
        ],
      ),
      Lesson(
        id: const Uuid().v4(),
        name: 'Coğrafya',
        colorValue: AppColors.geography.value,
        iconCodePoint: Icons.public.codePoint,
        subjects: [
          'Türkiye\'nin Coğrafi Konumu',
          'Türkiye\'de Yerşekilleri - Dağlar',
          'Türkiye\'nin İklimi',
          'Türkiye\'nin Beşeri Coğrafyası',
          'Türkiye\'nin Ekonomik Coğrafyası',
        ],
      ),
      Lesson(
        id: const Uuid().v4(),
        name: 'Vatandaşlık',
        colorValue: AppColors.civics.value,
        iconCodePoint: Icons.gavel.codePoint,
        subjects: [
          'Hukukun Temel Kavramları',
          'Anayasal Gelişmeler',
          'Temel Hak ve Ödevler',
          'Devletin Temel Organları',
          'İdare Hukuku',
        ],
      ),
      Lesson(
        id: const Uuid().v4(),
        name: 'Geometri',
        colorValue: AppColors.geometry.value,
        iconCodePoint: Icons.category.codePoint,
        subjects: [
          'Analitik Geometri',
          'Üçgenler',
          'Çokgenler',
          'Çember ve Daire',
          'Katı Cisimler',
        ],
      ),
      Lesson(
        id: const Uuid().v4(),
        name: 'Fizik',
        colorValue: AppColors.physics.value,
        iconCodePoint: Icons.science.codePoint,
        subjects: [
          'Mekanik',
          'Optik',
          'Dalgalar',
          'Elektrik ve Manyetizma',
          'Termodinamik',
          'Modern Fizik',
        ],
      ),
      Lesson(
        id: const Uuid().v4(),
        name: 'Kimya',
        colorValue: AppColors.chemistry.value,
        iconCodePoint: Icons.opacity.codePoint,
        subjects: [
          'Kimya Bilimi',
          'Atom ve Periyodik Sistem',
          'Kimyasal Türler Arası Etkileşimler',
          'Maddenin Halleri',
          'Karışımlar',
          'Asitler, Bazlar ve Tuzlar',
          'Kimya ve Enerji',
          'Organik Kimya',
        ],
      ),
      Lesson(
        id: const Uuid().v4(),
        name: 'Biyoloji',
        colorValue: AppColors.biology.value,
        iconCodePoint: Icons.spa.codePoint,
        subjects: [
          'Hücre ve Organelleri',
          'Canlıların Sınıflandırılması',
          'Kalıtım',
          'Ekosistem Ekolojisi',
          'Sistemler',
          'Bitki Biyolojisi',
        ],
      ),
      Lesson(
        id: const Uuid().v4(),
        name: 'İngilizce',
        colorValue: AppColors.english.value,
        iconCodePoint: Icons.language.codePoint,
        subjects: [
          'Kelime Bilgisi',
          'Dil Bilgisi (Grammar)',
          'Okuma Anlama',
          'Cümle Tamamlama',
          'Çeviri',
        ],
      ),
    ];

    for (var lesson in defaultLessons) {
      await box.put(lesson.id, lesson);
    }
  }

  Future<void> clearAllData() async {
    await Hive.box<Lesson>(AppConstants.lessonsBoxName).clear();
    await Hive.box<Mistake>(AppConstants.mistakesBoxName).clear();
    await Hive.box(AppConstants.settingsBoxName).clear();
    // Repopulate default lessons
    await _populateDefaultLessons(Hive.box<Lesson>(AppConstants.lessonsBoxName));
  }

  Future<void> _syncLessonSubjects(Box<Lesson> lessonsBox) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/questions/academy_questions.json');
      final List<dynamic> jsonList = json.decode(jsonStr);

      final Map<String, Set<String>> extractedSubjects = {
        'Tarih': {},
        'Coğrafya': {},
        'Vatandaşlık': {},
      };

      for (var q in jsonList) {
        final category = q['category'] as String?;
        final topic = q['topic'] as String?;
        if (category != null && topic != null && extractedSubjects.containsKey(category)) {
          extractedSubjects[category]!.add(topic);
        }
      }

      for (var entry in extractedSubjects.entries) {
        final lessonName = entry.key;
        final newSubjects = entry.value.toList()..sort();

        if (newSubjects.isEmpty) continue;

        final lesson = lessonsBox.values
            .where((l) => l.name == lessonName)
            .firstOrNull;

        if (lesson != null) {
          final Set<String> mergedSubjectsSet = {};
          mergedSubjectsSet.addAll(lesson.subjects);
          mergedSubjectsSet.addAll(newSubjects);
          final mergedSubjects = mergedSubjectsSet.toList()..sort();

          bool needsUpdate = lesson.subjects.length != mergedSubjects.length;
          if (!needsUpdate) {
            for (int i = 0; i < mergedSubjects.length; i++) {
              if (lesson.subjects[i] != mergedSubjects[i]) {
                needsUpdate = true;
                break;
              }
            }
          }

          if (needsUpdate) {
            final updated = lesson.copyWith(subjects: mergedSubjects);
            await lessonsBox.put(lesson.key, updated);
            debugPrint('Synced $lessonName with ${mergedSubjects.length} subjects (merged dynamic + manual).');
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing lesson subjects: $e');
    }
  }
}
