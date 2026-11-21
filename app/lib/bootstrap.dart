import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scamshield/app.dart';
import 'package:scamshield/core/config/app_config.dart';
import 'package:scamshield/core/di/injection.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.current = config;
  await configureDependencies(config.flavor.name);
  runApp(const ProviderScope(child: ScamShieldApp()));
}