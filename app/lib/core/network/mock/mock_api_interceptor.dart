import 'package:dio/dio.dart';
import 'package:scamshield/core/network/api_endpoints.dart';
import 'package:scamshield/core/network/mock/mock_data.dart';
import 'package:scamshield/core/network/mock/mock_scan_analyzer.dart';

/// Answers API calls locally until every backend endpoint is live.
/// Turn off completely with --dart-define=MOCK_API=false
///
/// LIVE_SCAN=true sends POST /scan/check to the real Go backend (API_URL)
/// and keeps everything else mocked. If the backend can't be reached
/// (laptop off, no internet), the scan falls back to the offline copy of
/// the rules, so the app never breaks in front of a user or a judge.
class MockApiInterceptor extends Interceptor {
  bool _paired = false;

  static const _liveScan = bool.fromEnvironment('LIVE_SCAN');

  bool _isScan(RequestOptions o) => o.method == 'POST' && o.path == ApiEndpoints.scanCheck;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_liveScan && _isScan(options)) {
      options.headers['ngrok-skip-browser-warning'] = 'true';
      options.connectTimeout = const Duration(seconds: 5);
      options.receiveTimeout = const Duration(seconds: 8);
      handler.next(options); // real backend
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 1200)); // shows the shimmer
    final body = _body(options);

    switch ((options.method, options.path)) {
      case ('POST', ApiEndpoints.scanCheck):
        _ok(handler, options, _offlineScan(body));
      case ('GET', ApiEndpoints.lessons):
        _ok(handler, options, MockData.lessons);
      case ('GET', ApiEndpoints.helplines):
        _ok(handler, options, MockData.helplines);
      case ('GET', ApiEndpoints.familyStatus):
        _ok(handler, options, _paired ? MockData.guardian() : <String, dynamic>{'paired': false});
      case ('POST', ApiEndpoints.familyPair):
        {
          if (body['code'] == '0000') {
            _fail(handler, options, 400); // try 0000 to see the error state
          } else {
            _paired = true;
            _ok(handler, options, MockData.guardian());
          }
        }
      default:
        _fail(handler, options, 404);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    if (_liveScan && _isScan(o)) {
      // Backend unreachable or erroring: answer with the offline rules instead.
      handler.resolve(Response<dynamic>(requestOptions: o, statusCode: 200, data: _offlineScan(_body(o))));
      return;
    }
    handler.next(err);
  }

  Map<String, dynamic> _body(RequestOptions o) =>
      o.data is Map ? Map<String, dynamic>.from(o.data as Map) : <String, dynamic>{};

  Map<String, dynamic> _offlineScan(Map<String, dynamic> body) =>
      MockScanAnalyzer.analyze(body['message'] as String? ?? '', body['sender'] as String?);

  void _ok(RequestInterceptorHandler handler, RequestOptions options, Object? data) {
    handler.resolve(Response<dynamic>(requestOptions: options, statusCode: 200, data: data));
  }

  void _fail(RequestInterceptorHandler handler, RequestOptions options, int status) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(requestOptions: options, statusCode: status),
      ),
    );
  }
}