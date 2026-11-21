import 'package:scamshield/features/simulator/domain/entities/lesson.dart';

abstract interface class LessonRepository {
  Future<List<Lesson>> getLessons({bool forceRefresh = false});
}