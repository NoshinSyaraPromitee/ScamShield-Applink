import 'package:injectable/injectable.dart';
import 'package:scamshield/core/cache/cached_fetcher.dart';
import 'package:scamshield/features/emergency/data/datasources/helpline_remote_data_source.dart';
import 'package:scamshield/features/emergency/data/models/helpline_model.dart';
import 'package:scamshield/features/emergency/domain/entities/helpline.dart';
import 'package:scamshield/features/emergency/domain/repositories/helpline_repository.dart';

@LazySingleton(as: HelplineRepository)
class HelplineRepositoryImpl implements HelplineRepository {
  HelplineRepositoryImpl(this._remote, this._fetcher);

  final HelplineRemoteDataSource _remote;
  final CachedFetcher _fetcher;

  /// Helplines rarely change, and must work offline in an emergency.
  @override
  Future<List<Helpline>> getHelplines() async {
    final result = await _fetcher.fetch(
      key: 'helplines',
      ttl: const Duration(days: 7),
      remote: _remote.getHelplines,
      parse: (json) => (json! as List)
          .map((e) => HelplineModel.fromJson(Map<String, dynamic>.from(e as Map)).toEntity())
          .toList(),
    );
    return result.data;
  }
}