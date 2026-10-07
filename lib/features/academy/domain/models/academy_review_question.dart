import 'package:hive/hive.dart';

part 'academy_review_question.g.dart';

@HiveType(typeId: 3)
class AcademyReviewQuestion extends HiveObject {
  @HiveField(0)
  final int questionId;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final String topic;

  @HiveField(3)
  final String difficulty;

  @HiveField(4)
  final String question;

  @HiveField(5)
  final List<String> options;

  @HiveField(6)
  final int correctAnswer;

  @HiveField(7)
  final String explanation;

  @HiveField(8)
  final int reviewStage; // 0 = 1 day, 1 = 3 days, 2 = 7 days, 3 = 15 days, 4 = 30 days, 5 = completed

  @HiveField(9)
  final DateTime nextReviewAt;

  @HiveField(10)
  final bool isCompleted;

  @HiveField(11)
  final DateTime createdAt;

  AcademyReviewQuestion({
    required this.questionId,
    required this.category,
    required this.topic,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.reviewStage,
    required this.nextReviewAt,
    required this.isCompleted,
    required this.createdAt,
  });

  AcademyReviewQuestion copyWith({
    int? questionId,
    String? category,
    String? topic,
    String? difficulty,
    String? question,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
    int? reviewStage,
    DateTime? nextReviewAt,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return AcademyReviewQuestion(
      questionId: questionId ?? this.questionId,
      category: category ?? this.category,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      reviewStage: reviewStage ?? this.reviewStage,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
