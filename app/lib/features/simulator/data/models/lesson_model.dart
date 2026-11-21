import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scamshield/features/simulator/domain/entities/lesson.dart';

part 'lesson_model.freezed.dart';
part 'lesson_model.g.dart';

@freezed
abstract class LessonModel with _$LessonModel {
  const LessonModel._();

  const factory LessonModel({
    required String id,
    required String sender,
    required String body,
    required bool isScam,
    @Default(<String>[]) List<String> signsBn,
    @Default(<String>[]) List<String> signsEn,
  }) = _LessonModel;

  factory LessonModel.fromJson(Map<String, dynamic> json) => _$LessonModelFromJson(json);

  Lesson toEntity() => Lesson(id: id, sender: sender, body: body, isScam: isScam, signsBn: signsBn, signsEn: signsEn);
}