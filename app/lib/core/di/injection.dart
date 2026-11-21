import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:scamshield/core/di/injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Environments match the flavor names: web, staging, production.
@InjectableInit()
Future<void> configureDependencies(String environment) async {
  await getIt.init(environment: environment);
}