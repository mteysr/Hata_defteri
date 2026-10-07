import 'package:hive/hive.dart';

part 'academy_answer_history.g.dart';

@HiveType(typeId: 4)
class AcademyAnswerHistory extends HiveObject {
  @HiveField(0)
  final String id; // UUID

  @HiveField(1)
  final int questionId;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String topic;

  @HiveField(4)
  final bool isCorrect;

  @HiveField(5)
  final DateTime answeredAt;

  AcademyAnswerHistory({
    required this.id,
    required this.questionId,
    required this.category,
    required this.topic,
    required this.isCorrect,
    required this.answeredAt,
  });
}
