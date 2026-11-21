import 'package:injectable/injectable.dart';
import 'package:scamshield/core/cache/cache_store.dart';
import 'package:scamshield/core/database/app_database.dart';

@LazySingleton(as: CacheStore, env: ['staging', 'production'])
class DriftCacheStore implements CacheStore {
  DriftCacheStore(this._db);

  final AppDatabase _db;

  @override
  Future<CacheEntry?> read(String key) async {
    final row = await (_db.select(_db.cachedResponses)..where((t) => t.cacheKey.equals(key))).getSingleOrNull();
    return row == null ? null : CacheEntry(payload: row.payload, savedAt: row.savedAt);
  }

  @override
  Future<void> write(String key, String payload) => _db.into(_db.cachedResponses).insertOnConflictUpdate(
        CachedResponsesCompanion.insert(cacheKey: key, payload: payload, savedAt: DateTime.now()),
      );

  @override
  Future<void> remove(String key) => (_db.delete(_db.cachedResponses)..where((t) => t.cacheKey.equals(key))).go();
}