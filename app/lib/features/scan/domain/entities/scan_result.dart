import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_result.freezed.dart';

enum RiskLevel { high, medium, low, none }

@freezed
abstract class ScanResult with _$ScanResult {
  const factory ScanResult({
    required String message,
    required RiskLevel risk,
    required double score,
    required List<String> reasonCodes,
    required List<String> highlights,
    @Default(false) bool fromCache,
  }) = _ScanResult;
}