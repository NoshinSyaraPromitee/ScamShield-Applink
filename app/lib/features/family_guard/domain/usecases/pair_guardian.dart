import 'package:injectable/injectable.dart';
import 'package:scamshield/core/network/failure.dart';
import 'package:scamshield/features/family_guard/domain/entities/guardian_link.dart';
import 'package:scamshield/features/family_guard/domain/repositories/guardian_repository.dart';

@injectable
class PairGuardian {
  const PairGuardian(this._repository);

  final GuardianRepository _repository;

  Future<GuardianLink> call(String code) {
    if (!RegExp(r'^\d{4}$').hasMatch(code)) throw const InvalidInputFailure();
    return _repository.pair(code);
  }
}