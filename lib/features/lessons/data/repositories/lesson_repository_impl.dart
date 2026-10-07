import 'package:hive/hive.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../models/lesson.dart';
import '../../../../core/constants/app_constants.dart';

class LessonRepositoryImpl implements LessonRepository {
  final Box<Lesson> _box;

  LessonRepositoryImpl() : _box = Hive.box<Lesson>(AppConstants.lessonsBoxName);

  @override
  List<Lesson> getLessons() {
    // Sort lessons alphabetically by name
    final list = _box.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Lesson? getLessonById(String id) {
    return _box.get(id);
  }

  @override
  Future<void> addLesson(Lesson lesson) async {
    await _box.put(lesson.id, lesson);
  }

  @override
  Future<void> updateLesson(Lesson lesson) async {
    await _box.put(lesson.id, lesson);
  }

  @override
  Future<void> deleteLesson(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> addSubject(String lessonId, String subject) async {
    final lesson = getLessonById(lessonId);
    if (lesson != null) {
      final trimmedSubject = subject.trim();
      if (trimmedSubject.isNotEmpty && !lesson.subjects.any((s) => s.toLowerCase() == trimmedSubject.toLowerCase())) {
        final updatedSubjects = List<String>.from(lesson.subjects)..add(trimmedSubject);
        final updatedLesson = lesson.copyWith(subjects: updatedSubjects);
        await updateLesson(updatedLesson);
      }
    }
  }
}
