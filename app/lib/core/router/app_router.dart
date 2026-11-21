import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scamshield/core/router/routes.dart';
import 'package:scamshield/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:scamshield/features/family_guard/presentation/screens/family_guard_screen.dart';
import 'package:scamshield/features/home/presentation/screens/home_screen.dart';
import 'package:scamshield/features/scan/presentation/screens/result_screen.dart';
import 'package:scamshield/features/scan/presentation/screens/scan_screen.dart';
import 'package:scamshield/features/settings/presentation/screens/settings_screen.dart';
import 'package:scamshield/features/simulator/presentation/screens/simulator_screen.dart';

export 'package:scamshield/core/router/routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      _route(Routes.home, (_) => const HomeScreen()),
      _route(Routes.scan, (state) => ScanScreen(initialText: state.extra as String?)),
      _route(Routes.result, (_) => const ResultScreen()),
      _route(Routes.simulator, (_) => const SimulatorScreen()),
      _route(Routes.emergency, (_) => const EmergencyScreen()),
      _route(Routes.family, (_) => const FamilyGuardScreen()),
      _route(Routes.settings, (_) => const SettingsScreen()),
    ],
  );
}

/// Calm fade-and-rise transition; instant when the phone asks for reduced motion.
GoRoute _route(String path, Widget Function(GoRouterState state) build) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: build(state),
      transitionDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}