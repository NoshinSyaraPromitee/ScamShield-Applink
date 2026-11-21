import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scamshield/features/scan/domain/entities/scan_result.dart';

part 'scan_result_model.freezed.dart';
part 'scan_result_model.g.dart';

@freezed
abstract class ScanResultModel with _$ScanResultModel {
  const ScanResultModel._();

  const factory ScanResultModel({
    required String risk,
    required double score,
    @Default(<String>[]) List<String> reasons,
    @Default(<String>[]) List<String> highlights,
  }) = _ScanResultModel;

  factory ScanResultModel.fromJson(Map<String, dynamic> json) => _$ScanResultModelFromJson(json);

  ScanResult toEntity({required String message, required bool fromCache}) => ScanResult(
        message: message,
        risk: RiskLevel.values.firstWhere((r) => r.name == risk, orElse: () => RiskLevel.none),
        score: score,
        reasonCodes: reasons,
        highlights: highlights,
        fromCache: fromCache,
      );
}