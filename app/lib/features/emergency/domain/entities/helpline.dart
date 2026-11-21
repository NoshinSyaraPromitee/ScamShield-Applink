import 'package:freezed_annotation/freezed_annotation.dart';

part 'helpline.freezed.dart';

@freezed
abstract class Helpline with _$Helpline {
  const Helpline._();

  const factory Helpline({
    required String id,
    required String nameBn,
    required String nameEn,
    required String number,
  }) = _Helpline;

  String name(String languageCode) => languageCode == 'bn' ? nameBn : nameEn;
}