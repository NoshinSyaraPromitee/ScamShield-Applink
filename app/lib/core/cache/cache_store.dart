class CacheEntry {
  const CacheEntry({required this.payload, required this.savedAt});

  final String payload;
  final DateTime savedAt;

  bool isFresh(Duration ttl) => DateTime.now().difference(savedAt) < ttl;
}

abstract interface class CacheStore {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, String payload);
  Future<void> remove(String key);
}