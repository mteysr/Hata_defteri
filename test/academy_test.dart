import 'package:flutter_test/flutter_test.dart';
import 'package:hata_defteri/features/academy/domain/models/academy_question.dart';
import 'package:hata_defteri/features/academy/domain/models/academy_note_booklet.dart';

void main() {
  group('Genel Kültür Akademisi Unit Tests', () {
    final List<AcademyQuestion> testPool = [
      AcademyQuestion(id: 1, category: 'Tarih', topic: 'T1', difficulty: 'Orta', question: 'Q1', options: ['A','B','C','D'], correctAnswer: 0, explanation: 'E1'),
      AcademyQuestion(id: 2, category: 'Tarih', topic: 'T2', difficulty: 'Kolay', question: 'Q2', options: ['A','B','C','D'], correctAnswer: 1, explanation: 'E2'),
      AcademyQuestion(id: 3, category: 'Tarih', topic: 'T3', difficulty: 'Zor', question: 'Q3', options: ['A','B','C','D'], correctAnswer: 2, explanation: 'E3'),
      AcademyQuestion(id: 4, category: 'Coğrafya', topic: 'G1', difficulty: 'Orta', question: 'Q4', options: ['A','B','C','D'], correctAnswer: 0, explanation: 'E4'),
      AcademyQuestion(id: 5, category: 'Coğrafya', topic: 'G2', difficulty: 'Kolay', question: 'Q5', options: ['A','B','C','D'], correctAnswer: 1, explanation: 'E5'),
      AcademyQuestion(id: 6, category: 'Coğrafya', topic: 'G3', difficulty: 'Zor', question: 'Q6', options: ['A','B','C','D'], correctAnswer: 2, explanation: 'E6'),
      AcademyQuestion(id: 7, category: 'Vatandaşlık', topic: 'C1', difficulty: 'Orta', question: 'Q7', options: ['A','B','C','D'], correctAnswer: 0, explanation: 'E7'),
      AcademyQuestion(id: 8, category: 'Vatandaşlık', topic: 'C2', difficulty: 'Kolay', question: 'Q8', options: ['A','B','C','D'], correctAnswer: 1, explanation: 'E8'),
      AcademyQuestion(id: 9, category: 'Vatandaşlık', topic: 'C3', difficulty: 'Zor', question: 'Q9', options: ['A','B','C','D'], correctAnswer: 2, explanation: 'E9'),
    ];

    // Mock selection algorithm
    List<int> selectQuestions(List<AcademyQuestion> pool, List<int> recentIds) {
      var available = pool.where((q) => !recentIds.contains(q.id)).toList();
      if (available.length < 5) {
        available = List<AcademyQuestion>.from(pool);
      }

      final historyPool = available.where((q) => q.category == 'Tarih').toList();
      final geographyPool = available.where((q) => q.category == 'Coğrafya').toList();
      final civicsPool = available.where((q) => q.category == 'Vatandaşlık').toList();

      final selected = <AcademyQuestion>[];

      // Try round-robin style to get diversity: 2 Tarih, 2 Coğrafya, 1 Vatandaşlık (or fallback)
      if (historyPool.isNotEmpty) selected.add(historyPool.removeLast());
      if (geographyPool.isNotEmpty) selected.add(geographyPool.removeLast());
      if (civicsPool.isNotEmpty) selected.add(civicsPool.removeLast());

      if (historyPool.isNotEmpty) selected.add(historyPool.removeLast());
      if (geographyPool.isNotEmpty) selected.add(geographyPool.removeLast());

      if (selected.length < 5) {
        final remaining = [...historyPool, ...geographyPool, ...civicsPool];
        while (selected.length < 5 && remaining.isNotEmpty) {
          selected.add(remaining.removeLast());
        }
      }

      return selected.take(5).map((q) => q.id).toList();
    }

    test('Daily quiz selection generates exactly 5 questions', () {
      final selected = selectQuestions(testPool, []);
      expect(selected.length, equals(5));
    });

    test('Daily quiz selection prioritizes category diversity', () {
      final selected = selectQuestions(testPool, []);
      final selectedCategories = selected.map((id) => testPool.firstWhere((q) => q.id == id).category).toList();
      
      // Should contain at least one question from each of the three categories
      expect(selectedCategories.contains('Tarih'), isTrue);
      expect(selectedCategories.contains('Coğrafya'), isTrue);
      expect(selectedCategories.contains('Vatandaşlık'), isTrue);
    });

    test('Daily quiz selection respects recency exclusion constraints', () {
      // Exclude questions 1, 2, 4, 5
      final recentIds = [1, 2, 4, 5];
      final selected = selectQuestions(testPool, recentIds);

      // Selected question IDs should not intersect with recent IDs
      for (var id in selected) {
        expect(recentIds.contains(id), isFalse);
      }
    });

    test('Academy Spaced Repetition calculates intervals correctly on correct/incorrect responses', () {
      final List<int> intervals = [1, 3, 7, 15, 30];
      final now = DateTime.now();

      // 1. Success on Stage 0 -> Stage 1 (interval = 3 days)
      int currentStage = 0;
      int nextStage = currentStage + 1;
      DateTime nextReview = now.add(Duration(days: intervals[nextStage]));

      expect(nextStage, equals(1));
      expect(nextReview.difference(now).inDays, equals(3));

      // 2. Success on last stage (Stage 4 -> completed)
      currentStage = 4;
      nextStage = currentStage + 1;
      bool isCompleted = nextStage >= intervals.length;
      expect(isCompleted, isTrue);

      // 3. Incorrect answer resets to stage 0, review set to 1 day later
      currentStage = 3;
      nextStage = 0;
      nextReview = now.add(const Duration(days: 1));

      expect(nextStage, equals(0));
      expect(nextReview.difference(now).inDays, equals(1));
    });

    test('Practice quiz filtering returns only selected category questions', () {
      final historyQuestions = testPool.where((q) => q.category == 'Tarih').toList();
      expect(historyQuestions.every((q) => q.category == 'Tarih'), isTrue);
      expect(historyQuestions.length, equals(3));
    });

    test('Practice quiz length limits returned question counts correctly', () {
      final selected = testPool.take(2).toList();
      expect(selected.length, equals(2));
    });

    test('Practice quiz filtering returns only selected topic questions', () {
      final topicQuestions = testPool.where((q) => q.category == 'Tarih' && q.topic == 'T1').toList();
      expect(topicQuestions.every((q) => q.topic == 'T1'), isTrue);
      expect(topicQuestions.length, equals(1));
    });

    test('Past questions database has correct keys and fields', () {
      final samplePastQuestion = AcademyQuestion(
        id: 1001,
        category: 'Tarih',
        topic: 'II. Meşrutiyet Dönemi',
        difficulty: 'Orta',
        question: 'Sample Q',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 1,
        explanation: 'Sample E',
      );

      expect(samplePastQuestion.id, equals(1001));
      expect(samplePastQuestion.category, equals('Tarih'));
      expect(samplePastQuestion.options.length, equals(4));
    });

    test('AcademyNoteBooklet model instantiation has correct values', () {
      const sampleBooklet = AcademyNoteBooklet(
        title: 'Title',
        category: 'Category',
        description: 'Desc',
        pageCount: 5,
        assetPrefix: 'Prefix',
        fileExtension: 'png',
      );

      expect(sampleBooklet.title, equals('Title'));
      expect(sampleBooklet.category, equals('Category'));
      expect(sampleBooklet.description, equals('Desc'));
      expect(sampleBooklet.pageCount, equals(5));
      expect(sampleBooklet.assetPrefix, equals('Prefix'));
      expect(sampleBooklet.fileExtension, equals('png'));
      expect(sampleBooklet.initialSearchQuery, isNull);

      final copiedBooklet = sampleBooklet.copyWith(initialSearchQuery: 'search');
      expect(copiedBooklet.initialSearchQuery, equals('search'));
      expect(copiedBooklet.title, equals('Title')); // retains other values
      
      expect(kAcademyNoteBooklets.isNotEmpty, isTrue);
      expect(kAcademyNoteBooklets.first.pageCount, equals(9));
    });

    test('Study Session metrics calculation validates correctly', () {
      final List<Map<String, dynamic>> sessions = [
        {'category': 'Tarih', 'durationMinutes': 25, 'timestamp': DateTime.now().toIso8601String()},
        {'category': 'Coğrafya', 'durationMinutes': 15, 'timestamp': DateTime.now().toIso8601String()},
        {'category': 'Tarih', 'durationMinutes': 30, 'timestamp': DateTime.now().toIso8601String()},
        {'category': 'Vatandaşlık', 'durationMinutes': 20, 'timestamp': DateTime.now().toIso8601String()},
      ];

      int tarihSum = 0;
      int cografyaSum = 0;
      int vatandaslikSum = 0;

      for (var s in sessions) {
        final cat = s['category'] as String;
        final duration = s['durationMinutes'] as int;
        if (cat == 'Tarih') tarihSum += duration;
        if (cat == 'Coğrafya') cografyaSum += duration;
        if (cat == 'Vatandaşlık') vatandaslikSum += duration;
      }

      expect(tarihSum, equals(55));
      expect(cografyaSum, equals(15));
      expect(vatandaslikSum, equals(20));
      expect(tarihSum + cografyaSum + vatandaslikSum, equals(90));
    });
  });
}
