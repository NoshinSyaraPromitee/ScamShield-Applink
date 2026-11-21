import 'package:dio/dio.dart';
import 'package:scamshield/core/config/app_config.dart';
import 'package:scamshield/core/storage/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeadersInterceptor extends Interceptor {
  HeadersInterceptor(this._prefs, this._config);

  final SharedPreferences _prefs;
  final AppConfig _config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _prefs.getString(PrefKeys.locale) ?? 'bn';
    options.headers['X-App-Flavor'] = _config.flavor.name;
    options.headers['X-Client'] = 'scamshield-flutter';
    handler.next(options);
  }
}