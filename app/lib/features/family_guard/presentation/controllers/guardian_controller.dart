import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scamshield/core/di/injection.dart';
import 'package:scamshield/core/network/failure.dart';
import 'package:scamshield/features/family_guard/domain/entities/guardian_link.dart';
import 'package:scamshield/features/family_guard/domain/usecases/get_guardian_status.dart';
import 'package:scamshield/features/family_guard/domain/usecases/pair_guardian.dart';

part 'guardian_controller.g.dart';

@riverpod
class GuardianController extends _$GuardianController {
  @override
  Future<GuardianLink> build() => getIt<GetGuardianStatus>()();

  /// Returns a failure for the form to show, or null when paired.
  Future<Failure?> pair(String code) async {
    try {
      final link = await getIt<PairGuardian>()(code);
      if (ref.mounted) state = AsyncData(link);
      return null;
    } on Failure catch (failure) {
      return failure;
    }
  }
}