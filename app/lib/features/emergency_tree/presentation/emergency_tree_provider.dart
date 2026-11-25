import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/emergency_tree_repository.dart';
import '../domain/emergency_tree.dart';

final emergencyTreeRepositoryProvider =
    Provider<EmergencyTreeRepository>((ref) => EmergencyTreeRepository());

final emergencyTreeProvider = FutureProvider<EmergencyTree>(
  (ref) => ref.watch(emergencyTreeRepositoryProvider).load(),
);