import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:scamshield/core/cache/cache_store.dart';
import 'package:scamshield/core/network/failure.dart';

class CacheResult<T> {
  const CacheResult(this.data, {required this.fromCache});
  final T data;
  final bool fromCache;
}

/// Cache-first: fresh cache wins; otherwise call the API and save.
/// When offline, falls back to stale cache instead of failing.
@lazySingleton
class CachedFetcher {
  CachedFetcher(this._cache);

  final CacheStore _cache;

  Future<CacheResult<T>> fetch<T>({
    required String key,
    required Duration ttl,
    required Future<Object?> Function() remote,
    required T Function(Object? json) parse,
    bool forceRefresh = false,
  }) async {
    final cached = await _cache.read(key);
    if (!forceRefresh && cached != null && cached.isFresh(ttl)) {
      return CacheResult(parse(jsonDecode(cached.payload)), fromCache: true);
    }
    try {
      final json = await remote();
      await _cache.write(key, jsonEncode(json));
      return CacheResult(parse(json), fromCache: false);
    } on NetworkFailure {
      if (cached != null) return CacheResult(parse(jsonDecode(cached.payload)), fromCache: true);
      rethrow;
    }
  }

  Future<void> put(String key, Object? json) => _cache.write(key, jsonEncode(json));

  Future<void> invalidate(String key) => _cache.remove(key);
}