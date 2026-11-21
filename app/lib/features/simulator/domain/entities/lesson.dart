import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson.freezed.dart';

@freezed
abstract class Lesson with _$Lesson {
  const Lesson._();

  const factory Lesson({
    required String id,
    required String sender,
    required String body,
    required bool isScam,
    required List<String> signsBn,
    required List<String> signsEn,
  }) = _Lesson;

  List<String> signs(String languageCode) => languageCode == 'bn' ? signsBn : signsEn;
}