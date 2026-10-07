import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../../../core/providers/repository_providers.dart';

final lessonListProvider = StateNotifierProvider<LessonListNotifier, List<Lesson>>((ref) {
  final repo = ref.watch(lessonRepositoryProvider);
  return LessonListNotifier(repo);
});

class LessonListNotifier extends StateNotifier<List<Lesson>> {
  final LessonRepository _repo;

  LessonListNotifier(this._repo) : super([]) {
    loadLessons();
  }

  void loadLessons() {
    state = _repo.getLessons();
  }

  Future<void> addLesson(Lesson lesson) async {
    await _repo.addLesson(lesson);
    loadLessons();
  }

  Future<void> updateLesson(Lesson lesson) async {
    await _repo.updateLesson(lesson);
    loadLessons();
  }

  Future<void> deleteLesson(String id) async {
    await _repo.deleteLesson(id);
    loadLessons();
  }

  Future<void> addSubject(String lessonId, String subject) async {
    await _repo.addSubject(lessonId, subject);
    loadLessons();
  }
}
