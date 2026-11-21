import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:scamshield/core/cache/cached_fetcher.dart';
import 'package:scamshield/features/scan/data/datasources/scan_remote_data_source.dart';
import 'package:scamshield/features/scan/data/models/scan_result_model.dart';
import 'package:scamshield/features/scan/domain/entities/scan_result.dart';
import 'package:scamshield/features/scan/domain/repositories/scan_repository.dart';

@LazySingleton(as: ScanRepository)
class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl(this._remote, this._fetcher);

  final ScanRemoteDataSource _remote;
  final CachedFetcher _fetcher;

  /// The same message checked again within a day comes from the phone, not the API.
  static const _ttl = Duration(days: 1);

  @override
  Future<ScanResult> check({required String message, String? sender}) async {
    final key = 'scan:${sha256.convert(utf8.encode('${sender ?? ''}|$message'))}';
    final result = await _fetcher.fetch(
      key: key,
      ttl: _ttl,
      remote: () => _remote.check(message: message, sender: sender),
      parse: (json) => ScanResultModel.fromJson(json! as Map<String, dynamic>),
    );
    return result.data.toEntity(message: message, fromCache: result.fromCache);
  }
}