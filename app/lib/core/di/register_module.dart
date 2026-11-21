import 'package:dio/dio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';
import 'package:scamshield/core/config/app_config.dart';
import 'package:scamshield/core/network/interceptors/headers_interceptor.dart';
import 'package:scamshield/core/network/interceptors/retry_interceptor.dart';
import 'package:scamshield/core/network/mock/mock_api_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class RegisterModule {
  @singleton
  AppConfig get config => AppConfig.current;

  @preResolve
  @singleton
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  FlutterTts get tts => FlutterTts();

  @lazySingleton
  Dio dio(AppConfig config, SharedPreferences prefs) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
      ),
    );
    dio.interceptors.addAll([
      HeadersInterceptor(prefs, config),
      RetryInterceptor(dio),
      if (!config.isProduction) LogInterceptor(requestBody: true, responseBody: true),
      if (config.useMockApi) MockApiInterceptor(),
    ]);
    return dio;
  }
}