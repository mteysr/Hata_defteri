import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/lessons/domain/repositories/lesson_repository.dart';
import '../../features/lessons/data/repositories/lesson_repository_impl.dart';
import '../../features/mistakes/domain/repositories/mistake_repository.dart';
import '../../features/mistakes/data/repositories/mistake_repository_impl.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepositoryImpl();
});

final mistakeRepositoryProvider = Provider<MistakeRepository>((ref) {
  return MistakeRepositoryImpl();
});
