import 'package:scamshield/features/family_guard/domain/entities/guardian_link.dart';

abstract interface class GuardianRepository {
  Future<GuardianLink> getStatus();
  Future<GuardianLink> pair(String code);
}