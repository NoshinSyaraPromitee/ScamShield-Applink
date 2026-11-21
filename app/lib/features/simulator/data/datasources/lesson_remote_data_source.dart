import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:scamshield/core/network/api_endpoints.dart';
import 'package:scamshield/core/network/failure.dart';

@lazySingleton
class LessonRemoteDataSource {
  LessonRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Object?> getLessons() => guardRequest(() async => (await _dio.get<Object?>(ApiEndpoints.lessons)).data);
}