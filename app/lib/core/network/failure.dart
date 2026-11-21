import 'package:dio/dio.dart';

sealed class Failure implements Exception {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class ServerFailure extends Failure {
  const ServerFailure([this.statusCode]);
  final int? statusCode;
}

final class InvalidInputFailure extends Failure {
  const InvalidInputFailure();
}

final class UnknownFailure extends Failure {
  const UnknownFailure();
}

/// Turns Dio errors into domain failures so the UI never sees DioException.
Future<T> guardRequest<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        throw const NetworkFailure();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 400 || code == 422) throw const InvalidInputFailure();
        throw ServerFailure(code);
      default:
        throw const UnknownFailure();
    }
  }
}