import '../../data/models/lesson.dart';

abstract class LessonRepository {
  List<Lesson> getLessons();
  Lesson? getLessonById(String id);
  Future<void> addLesson(Lesson lesson);
  Future<void> updateLesson(Lesson lesson);
  Future<void> deleteLesson(String id);
  Future<void> addSubject(String lessonId, String subject);
}
