import 'package:injectable/injectable.dart';
import 'package:scamshield/features/simulator/domain/entities/lesson.dart';
import 'package:scamshield/features/simulator/domain/repositories/lesson_repository.dart';

@injectable
class GetLessons {
  const GetLessons(this._repository);

  final LessonRepository _repository;

  Future<List<Lesson>> call({bool forceRefresh = false}) => _repository.getLessons(forceRefresh: forceRefresh);
}