import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scamshield/core/di/injection.dart';
import 'package:scamshield/features/simulator/domain/entities/lesson.dart';
import 'package:scamshield/features/simulator/domain/usecases/get_lessons.dart';

part 'lessons_provider.g.dart';

@riverpod
Future<List<Lesson>> lessons(Ref ref) => getIt<GetLessons>()();