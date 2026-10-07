// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_review_question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AcademyReviewQuestionAdapter extends TypeAdapter<AcademyReviewQuestion> {
  @override
  final int typeId = 3;

  @override
  AcademyReviewQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AcademyReviewQuestion(
      questionId: fields[0] as int,
      category: fields[1] as String,
      topic: fields[2] as String,
      difficulty: fields[3] as String,
      question: fields[4] as String,
      options: (fields[5] as List).cast<String>(),
      correctAnswer: fields[6] as int,
      explanation: fields[7] as String,
      reviewStage: fields[8] as int,
      nextReviewAt: fields[9] as DateTime,
      isCompleted: fields[10] as bool,
      createdAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AcademyReviewQuestion obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.topic)
      ..writeByte(3)
      ..write(obj.difficulty)
      ..writeByte(4)
      ..write(obj.question)
      ..writeByte(5)
      ..write(obj.options)
      ..writeByte(6)
      ..write(obj.correctAnswer)
      ..writeByte(7)
      ..write(obj.explanation)
      ..writeByte(8)
      ..write(obj.reviewStage)
      ..writeByte(9)
      ..write(obj.nextReviewAt)
      ..writeByte(10)
      ..write(obj.isCompleted)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademyReviewQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
