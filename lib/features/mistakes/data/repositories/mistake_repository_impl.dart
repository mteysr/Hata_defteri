import 'package:hive/hive.dart';
import '../../domain/repositories/mistake_repository.dart';
import '../../domain/models/mistake.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/file_service.dart';

class MistakeRepositoryImpl implements MistakeRepository {
  final Box<Mistake> _box;
  final FileService _fileService;

  MistakeRepositoryImpl({FileService? fileService})
      : _box = Hive.box<Mistake>(AppConstants.mistakesBoxName),
        _fileService = fileService ?? FileService.instance;

  @override
  List<Mistake> getMistakes() {
    final list = _box.values.toList();
    // Sort by created date descending by default
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Mistake? getMistakeById(String id) {
    return _box.get(id);
  }

  @override
  Future<void> addMistake(Mistake mistake) async {
    await _box.put(mistake.id, mistake);
  }

  @override
  Future<void> updateMistake(Mistake mistake) async {
    await _box.put(mistake.id, mistake);
  }

  @override
  Future<void> deleteMistake(String id) async {
    final mistake = getMistakeById(id);
    if (mistake != null) {
      await _fileService.deleteImage(mistake.questionImagePath);
      if (mistake.solutionImagePath != null) {
        await _fileService.deleteImage(mistake.solutionImagePath);
      }
    }
    await _box.delete(id);
  }
}
