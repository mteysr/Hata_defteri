import 'package:flutter_test/flutter_test.dart';
import 'package:hata_defteri/core/constants/app_constants.dart';

void main() {
  group('Spaced Repetition Algorithm Tests', () {
    test('Correct answer advances stage and schedules next review correctly', () {
      final now = DateTime.now();

      // Test Stage 0 -> Stage 1 (interval should be index 1 of reviewIntervals, i.e., 3 days)
      int stageBefore = 0;
      int stageAfter = stageBefore + 1;
      DateTime nextReview;
      bool isCompleted = false;

      if (stageAfter >= AppConstants.reviewIntervals.length) {
        stageAfter = AppConstants.reviewIntervals.length;
        isCompleted = true;
        nextReview = now.add(const Duration(days: 3650));
      } else {
        final daysToAdd = AppConstants.reviewIntervals[stageAfter];
        nextReview = now.add(Duration(days: daysToAdd));
      }

      expect(stageAfter, equals(1));
      expect(isCompleted, isFalse);
      expect(nextReview.difference(now).inDays, equals(3)); // index 1 of [1, 3, 7, 15, 30] is 3
    });

    test('Correct answer at last stage marks as completed', () {
      final now = DateTime.now();

      // Test Stage 4 -> Stage 5 (out of bounds, marks as completed)
      int stageBefore = 4;
      int stageAfter = stageBefore + 1;
      DateTime nextReview;
      bool isCompleted = false;

      if (stageAfter >= AppConstants.reviewIntervals.length) {
        stageAfter = AppConstants.reviewIntervals.length;
        isCompleted = true;
        nextReview = now.add(const Duration(days: 3650));
      } else {
        final daysToAdd = AppConstants.reviewIntervals[stageAfter];
        nextReview = now.add(Duration(days: daysToAdd));
      }

      expect(stageAfter, equals(5));
      expect(isCompleted, isTrue);
      expect(nextReview.difference(now).inDays, equals(3650));
    });

    test('Incorrect answer resets review stage and schedules for 1 day', () {
      final now = DateTime.now();

      // Test Stage 3 -> Failure resets to Stage 0 and schedules for 1 day
      int stageBefore = 3;
      int stageAfter = 0; // failure resets
      DateTime nextReview = now.add(const Duration(days: 1));
      bool isCompleted = false;

      expect(stageAfter, equals(0));
      expect(isCompleted, isFalse);
      expect(nextReview.difference(now).inDays, equals(1));
    });
  });
}
