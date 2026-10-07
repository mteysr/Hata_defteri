import 'package:hive/hive.dart';

part 'review_attempt.g.dart';

@HiveType(typeId: 2)
class ReviewAttempt extends HiveObject {
  @HiveField(0)
  final DateTime attemptedAt;

  @HiveField(1)
  final bool isCorrect;

  @HiveField(2)
  final int stageBefore;

  @HiveField(3)
  final int stageAfter;

  ReviewAttempt({
    required this.attemptedAt,
    required this.isCorrect,
    required this.stageBefore,
    required this.stageAfter,
  });
}
