import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:scamshield/bootstrap.dart';
import 'package:scamshield/core/config/app_config.dart';

// Plain `flutter run` / the IDE play button: the web build must use the web
// flavor (in-memory cache). The staging flavor uses a Drift/SQLite cache that
// needs extra wasm files on web, which made every cached screen fail.
void main() => bootstrap(kIsWeb ? AppConfig.web : AppConfig.staging);
