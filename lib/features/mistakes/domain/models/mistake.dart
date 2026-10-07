import 'package:hive/hive.dart';
import '../../../../core/services/file_service.dart';
import 'review_attempt.dart';

part 'mistake.g.dart';

@HiveType(typeId: 1)
class Mistake extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String lessonId;

  @HiveField(2)
  final String subject;

  @HiveField(3)
  final String? sourceBook;

  @HiveField(4)
  final String? mockExamName;

  @HiveField(5)
  final String? testName;

  @HiveField(6)
  final int? pageNumber;

  @HiveField(7)
  final int? questionNumber;

  @HiveField(8)
  final String difficulty; // EASY, MEDIUM, HARD

  @HiveField(9)
  final String reason; // CARELESSNESS, LACK_OF_KNOWLEDGE, CALCULATION_ERROR, MISREADING, OUT_OF_TIME, OTHER

  @HiveField(10)
  final String? note;

  @HiveField(11)
  final List<String> tags;

  @HiveField(12)
  final String questionImagePath;

  @HiveField(13)
  final String? solutionImagePath;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime nextReviewAt;

  @HiveField(16)
  final int reviewStage; // 0, 1, 2, 3, 4, 5

  @HiveField(17)
  final bool isCompleted;

  @HiveField(18)
  final List<ReviewAttempt> reviewAttempts;

  @HiveField(19)
  final String? correctAnswerOption;

  Mistake({
    required this.id,
    required this.lessonId,
    required this.subject,
    this.sourceBook,
    this.mockExamName,
    this.testName,
    this.pageNumber,
    this.questionNumber,
    required this.difficulty,
    required this.reason,
    this.note,
    required this.tags,
    required this.questionImagePath,
    this.solutionImagePath,
    required this.createdAt,
    required this.nextReviewAt,
    required this.reviewStage,
    required this.isCompleted,
    required this.reviewAttempts,
    this.correctAnswerOption,
  });

  String get questionImageFile => FileService.getActualPath(questionImagePath);
  String? get solutionImageFile => solutionImagePath == null || solutionImagePath!.isEmpty 
      ? null 
      : FileService.getActualPath(solutionImagePath!);

  Mistake copyWith({
    String? id,
    String? lessonId,
    String? subject,
    String? sourceBook,
    String? mockExamName,
    String? testName,
    int? pageNumber,
    int? questionNumber,
    String? difficulty,
    String? reason,
    String? note,
    List<String>? tags,
    String? questionImagePath,
    String? solutionImagePath,
    DateTime? createdAt,
    DateTime? nextReviewAt,
    int? reviewStage,
    bool? isCompleted,
    List<ReviewAttempt>? reviewAttempts,
    String? correctAnswerOption,
  }) {
    return Mistake(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      subject: subject ?? this.subject,
      sourceBook: sourceBook ?? this.sourceBook,
      mockExamName: mockExamName ?? this.mockExamName,
      testName: testName ?? this.testName,
      pageNumber: pageNumber ?? this.pageNumber,
      questionNumber: questionNumber ?? this.questionNumber,
      difficulty: difficulty ?? this.difficulty,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      questionImagePath: questionImagePath ?? this.questionImagePath,
      solutionImagePath: solutionImagePath ?? this.solutionImagePath,
      createdAt: createdAt ?? this.createdAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      reviewStage: reviewStage ?? this.reviewStage,
      isCompleted: isCompleted ?? this.isCompleted,
      reviewAttempts: reviewAttempts ?? this.reviewAttempts,
      correctAnswerOption: correctAnswerOption ?? this.correctAnswerOption,
    );
  }
}
