import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:scamshield/core/network/api_endpoints.dart';
import 'package:scamshield/core/network/failure.dart';

@lazySingleton
class ScanRemoteDataSource {
  ScanRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Object?> check({required String message, String? sender}) => guardRequest(() async {
        final response = await _dio.post<Object?>(
          ApiEndpoints.scanCheck,
          data: {'message': message, 'sender': sender},
        );
        return response.data;
      });
}