enum Flavor { web, staging, production }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.baseUrl,
    required this.useMockApi,
  });

  final Flavor flavor;
  final String appName;
  final String baseUrl;
  final bool useMockApi;

  bool get isProduction => flavor == Flavor.production;

  /// Set once in bootstrap() before dependency injection runs.
  static late AppConfig current;

  static const web = AppConfig(
    flavor: Flavor.web,
    appName: 'ScamShield (Web)',
    baseUrl: String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080/api/v1'),
    useMockApi: bool.fromEnvironment('MOCK_API', defaultValue: true),
  );

  static const staging = AppConfig(
    flavor: Flavor.staging,
    appName: 'ScamShield (Staging)',
    // 10.0.2.2 = your computer, seen from the Android emulator.
    baseUrl: String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080/api/v1'),
    useMockApi: bool.fromEnvironment('MOCK_API', defaultValue: true),
  );

  static const production = AppConfig(
    flavor: Flavor.production,
    appName: 'ScamShield BD',
    baseUrl: String.fromEnvironment('API_URL', defaultValue: 'https://api.scamshield.example/api/v1'),
    useMockApi: bool.fromEnvironment('MOCK_API', defaultValue: false),
  );
}