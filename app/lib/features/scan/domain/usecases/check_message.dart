import 'package:injectable/injectable.dart';
import 'package:scamshield/core/network/failure.dart';
import 'package:scamshield/features/scan/domain/entities/scan_result.dart';
import 'package:scamshield/features/scan/domain/repositories/scan_repository.dart';

@injectable
class CheckMessage {
  const CheckMessage(this._repository);

  final ScanRepository _repository;

  Future<ScanResult> call({required String message, String? sender}) {
    final text = message.trim();
    if (text.length < 4) throw const InvalidInputFailure();
    final cleanSender = sender?.trim();
    return _repository.check(
      message: text,
      sender: (cleanSender == null || cleanSender.isEmpty) ? null : cleanSender,
    );
  }
}