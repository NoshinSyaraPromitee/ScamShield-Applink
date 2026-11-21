import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scamshield/features/family_guard/domain/entities/guardian_link.dart';

part 'guardian_link_model.freezed.dart';
part 'guardian_link_model.g.dart';

@freezed
abstract class GuardianLinkModel with _$GuardianLinkModel {
  const GuardianLinkModel._();

  const factory GuardianLinkModel({
    required bool paired,
    String? name,
    DateTime? lastAlertAt,
  }) = _GuardianLinkModel;

  factory GuardianLinkModel.fromJson(Map<String, dynamic> json) => _$GuardianLinkModelFromJson(json);

  GuardianLink toEntity() => GuardianLink(paired: paired, name: name, lastAlertAt: lastAlertAt);
}