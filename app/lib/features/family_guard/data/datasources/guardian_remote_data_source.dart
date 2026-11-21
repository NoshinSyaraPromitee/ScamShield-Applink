import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:scamshield/core/network/api_endpoints.dart';
import 'package:scamshield/core/network/failure.dart';

@lazySingleton
class GuardianRemoteDataSource {
  GuardianRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Object?> getStatus() => guardRequest(() async => (await _dio.get<Object?>(ApiEndpoints.familyStatus)).data);

  Future<Object?> pair(String code) =>
      guardRequest(() async => (await _dio.post<Object?>(ApiEndpoints.familyPair, data: {'code': code})).data);
}