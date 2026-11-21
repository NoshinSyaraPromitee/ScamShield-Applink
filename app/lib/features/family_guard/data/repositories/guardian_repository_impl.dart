import 'package:injectable/injectable.dart';
import 'package:scamshield/core/cache/cached_fetcher.dart';
import 'package:scamshield/features/family_guard/data/datasources/guardian_remote_data_source.dart';
import 'package:scamshield/features/family_guard/data/models/guardian_link_model.dart';
import 'package:scamshield/features/family_guard/domain/entities/guardian_link.dart';
import 'package:scamshield/features/family_guard/domain/repositories/guardian_repository.dart';

@LazySingleton(as: GuardianRepository)
class GuardianRepositoryImpl implements GuardianRepository {
  GuardianRepositoryImpl(this._remote, this._fetcher);

  final GuardianRemoteDataSource _remote;
  final CachedFetcher _fetcher;
  static const _statusKey = 'family:status';

  @override
  Future<GuardianLink> getStatus() async {
    final result = await _fetcher.fetch(
      key: _statusKey,
      ttl: const Duration(minutes: 5),
      remote: _remote.getStatus,
      parse: (json) => GuardianLinkModel.fromJson(Map<String, dynamic>.from(json! as Map)),
    );
    return result.data.toEntity();
  }

  @override
  Future<GuardianLink> pair(String code) async {
    final json = await _remote.pair(code);
    await _fetcher.put(_statusKey, json); // next open shows "protected" instantly
    return GuardianLinkModel.fromJson(Map<String, dynamic>.from(json! as Map)).toEntity();
  }
}