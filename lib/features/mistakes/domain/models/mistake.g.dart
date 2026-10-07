// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mistake.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MistakeAdapter extends TypeAdapter<Mistake> {
  @override
  final int typeId = 1;

  @override
  Mistake read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mistake(
      id: fields[0] as String,
      lessonId: fields[1] as String,
      subject: fields[2] as String,
      sourceBook: fields[3] as String?,
      mockExamName: fields[4] as String?,
      testName: fields[5] as String?,
      pageNumber: fields[6] as int?,
      questionNumber: fields[7] as int?,
      difficulty: fields[8] as String,
      reason: fields[9] as String,
      note: fields[10] as String?,
      tags: (fields[11] as List).cast<String>(),
      questionImagePath: fields[12] as String,
      solutionImagePath: fields[13] as String?,
      createdAt: fields[14] as DateTime,
      nextReviewAt: fields[15] as DateTime,
      reviewStage: fields[16] as int,
      isCompleted: fields[17] as bool,
      reviewAttempts: (fields[18] as List).cast<ReviewAttempt>(),
      correctAnswerOption: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Mistake obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lessonId)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.sourceBook)
      ..writeByte(4)
      ..write(obj.mockExamName)
      ..writeByte(5)
      ..write(obj.testName)
      ..writeByte(6)
      ..write(obj.pageNumber)
      ..writeByte(7)
      ..write(obj.questionNumber)
      ..writeByte(8)
      ..write(obj.difficulty)
      ..writeByte(9)
      ..write(obj.reason)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.questionImagePath)
      ..writeByte(13)
      ..write(obj.solutionImagePath)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.nextReviewAt)
      ..writeByte(16)
      ..write(obj.reviewStage)
      ..writeByte(17)
      ..write(obj.isCompleted)
      ..writeByte(18)
      ..write(obj.reviewAttempts)
      ..writeByte(19)
      ..write(obj.correctAnswerOption);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MistakeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
