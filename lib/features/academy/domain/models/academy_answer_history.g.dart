// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_answer_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AcademyAnswerHistoryAdapter extends TypeAdapter<AcademyAnswerHistory> {
  @override
  final int typeId = 4;

  @override
  AcademyAnswerHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AcademyAnswerHistory(
      id: fields[0] as String,
      questionId: fields[1] as int,
      category: fields[2] as String,
      topic: fields[3] as String,
      isCorrect: fields[4] as bool,
      answeredAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AcademyAnswerHistory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.questionId)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.topic)
      ..writeByte(4)
      ..write(obj.isCorrect)
      ..writeByte(5)
      ..write(obj.answeredAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademyAnswerHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
