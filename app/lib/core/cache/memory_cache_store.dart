import 'package:injectable/injectable.dart';
import 'package:scamshield/core/cache/cache_store.dart';

@LazySingleton(as: CacheStore, env: ['web'])
class MemoryCacheStore implements CacheStore {
  final _store = <String, CacheEntry>{};

  @override
  Future<CacheEntry?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String payload) async {
    _store[key] = CacheEntry(payload: payload, savedAt: DateTime.now());
  }

  @override
  Future<void> remove(String key) async => _store.remove(key);
}