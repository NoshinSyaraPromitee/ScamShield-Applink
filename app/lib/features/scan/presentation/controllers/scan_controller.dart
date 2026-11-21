import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scamshield/core/di/injection.dart';
import 'package:scamshield/features/scan/domain/entities/scan_result.dart';
import 'package:scamshield/features/scan/domain/usecases/check_message.dart';

part 'scan_controller.g.dart';

/// Kept alive so the result survives moving from the check screen to the result screen.
@Riverpod(keepAlive: true)
class ScanController extends _$ScanController {
  String _lastMessage = '';
  String? _lastSender;

  @override
  FutureOr<ScanResult?> build() => null;

  Future<void> check({required String message, String? sender}) async {
    _lastMessage = message;
    _lastSender = sender;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() => getIt<CheckMessage>()(message: message, sender: sender));
    if (!ref.mounted) return;
    state = next;
  }

  Future<void> retry() => check(message: _lastMessage, sender: _lastSender);
}