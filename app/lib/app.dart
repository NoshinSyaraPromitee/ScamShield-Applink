import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scamshield/core/config/app_config.dart';
import 'package:scamshield/core/di/injection.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/router/app_router.dart';
import 'package:scamshield/core/settings/settings_controller.dart';
import 'package:scamshield/core/sharing/share_listener.dart';
import 'package:scamshield/core/theme/app_theme.dart';

class ScamShieldApp extends HookConsumerWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final config = getIt<AppConfig>();
    useShareIntent(router);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: !config.isProduction,
      theme: AppTheme.light(),
      locale: Locale(settings.languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: settings.largeText ? 1.15 : 1.0,
              maxScaleFactor: 1.6,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}