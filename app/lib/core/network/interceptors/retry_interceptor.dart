import 'package:dio/dio.dart';

/// Retries a request up to [maxRetries] times on timeouts and dropped connections.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 2});

  final Dio _dio;
  final int maxRetries;
  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    if (!retryable || attempt >= maxRetries) {
      handler.next(err);
      return;
    }
    await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}