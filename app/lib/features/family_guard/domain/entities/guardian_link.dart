import 'package:freezed_annotation/freezed_annotation.dart';

part 'guardian_link.freezed.dart';

@freezed
abstract class GuardianLink with _$GuardianLink {
  const factory GuardianLink({
    required bool paired,
    String? name,
    DateTime? lastAlertAt,
  }) = _GuardianLink;
}