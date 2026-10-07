// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_attempt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReviewAttemptAdapter extends TypeAdapter<ReviewAttempt> {
  @override
  final int typeId = 2;

  @override
  ReviewAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReviewAttempt(
      attemptedAt: fields[0] as DateTime,
      isCorrect: fields[1] as bool,
      stageBefore: fields[2] as int,
      stageAfter: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ReviewAttempt obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.attemptedAt)
      ..writeByte(1)
      ..write(obj.isCorrect)
      ..writeByte(2)
      ..write(obj.stageBefore)
      ..writeByte(3)
      ..write(obj.stageAfter);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewAttemptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
