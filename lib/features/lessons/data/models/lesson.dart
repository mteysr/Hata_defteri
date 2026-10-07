import 'package:hive/hive.dart';

part 'lesson.g.dart';

@HiveType(typeId: 0)
class Lesson extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final int iconCodePoint;

  @HiveField(4)
  final List<String> subjects;

  Lesson({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.subjects,
  });

  Lesson copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    List<String>? subjects,
  }) {
    return Lesson(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      subjects: subjects ?? this.subjects,
    );
  }
}
