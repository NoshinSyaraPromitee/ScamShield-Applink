import 'package:dio/dio.dart';
import 'package:scamshield/core/network/api_endpoints.dart';
import 'package:scamshield/core/network/mock/mock_data.dart';
import 'package:scamshield/core/network/mock/mock_scan_analyzer.dart';

/// Answers API calls locally until the Go backend is live.
/// Turn off with --dart-define=MOCK_API=false
class MockApiInterceptor extends Interceptor {
  bool _paired = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200)); // shows the shimmer
    final body = options.data is Map ? Map<String, dynamic>.from(options.data as Map) : <String, dynamic>{};

    switch ((options.method, options.path)) {
      case ('POST', ApiEndpoints.scanCheck):
        {
          final message = body['message'] as String? ?? '';
          final sender = body['sender'] as String?;
          _ok(handler, options, MockScanAnalyzer.analyze(message, sender));
        }
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