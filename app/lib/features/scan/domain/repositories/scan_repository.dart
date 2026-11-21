import 'package:scamshield/features/scan/domain/entities/scan_result.dart';

abstract interface class ScanRepository {
  Future<ScanResult> check({required String message, String? sender});
}