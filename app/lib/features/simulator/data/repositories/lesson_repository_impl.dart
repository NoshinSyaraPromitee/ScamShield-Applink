import 'package:injectable/injectable.dart';
import 'package:scamshield/core/cache/cached_fetcher.dart';
import 'package:scamshield/features/simulator/data/datasources/lesson_remote_data_source.dart';
import 'package:scamshield/features/simulator/data/models/lesson_model.dart';
import 'package:scamshield/features/simulator/domain/entities/lesson.dart';
import 'package:scamshield/features/simulator/domain/repositories/lesson_repository.dart';

@LazySingleton(as: LessonRepository)
class LessonRepositoryImpl implements LessonRepository {
  LessonRepositoryImpl(this._remote, this._fetcher);

  final LessonRemoteDataSource _remote;
  final CachedFetcher _fetcher;

  @override
  Future<List<Lesson>> getLessons({bool forceRefresh = false}) async {
    final result = await _fetcher.fetch(
      key: 'lessons',
      ttl: const Duration(hours: 12),
      forceRefresh: forceRefresh,
      remote: _remote.getLessons,
      parse: (json) => (json! as List)
          .map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e as Map)).toEntity())
          .toList(),
    );
    return result.data;
  }
}