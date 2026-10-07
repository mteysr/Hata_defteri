import '../models/mistake.dart';

abstract class MistakeRepository {
  List<Mistake> getMistakes();
  Mistake? getMistakeById(String id);
  Future<void> addMistake(Mistake mistake);
  Future<void> updateMistake(Mistake mistake);
  Future<void> deleteMistake(String id);
}
