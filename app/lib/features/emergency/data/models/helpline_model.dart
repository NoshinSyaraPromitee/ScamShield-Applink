import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scamshield/features/emergency/domain/entities/helpline.dart';

part 'helpline_model.freezed.dart';
part 'helpline_model.g.dart';

@freezed
abstract class HelplineModel with _$HelplineModel {
  const HelplineModel._();

  const factory HelplineModel({
    required String id,
    required String nameBn,
    required String nameEn,
    required String number,
  }) = _HelplineModel;

  factory HelplineModel.fromJson(Map<String, dynamic> json) => _$HelplineModelFromJson(json);

  Helpline toEntity() => Helpline(id: id, nameBn: nameBn, nameEn: nameEn, number: number);
}