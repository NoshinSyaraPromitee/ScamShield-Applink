import 'package:injectable/injectable.dart';
import 'package:scamshield/features/family_guard/domain/entities/guardian_link.dart';
import 'package:scamshield/features/family_guard/domain/repositories/guardian_repository.dart';

@injectable
class GetGuardianStatus {
  const GetGuardianStatus(this._repository);

  final GuardianRepository _repository;

  Future<GuardianLink> call() => _repository.getStatus();
}