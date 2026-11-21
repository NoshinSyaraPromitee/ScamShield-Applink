import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

part 'app_database.g.dart';

@DataClassName('CacheRow')
class CachedResponses extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get payload => text()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

@LazySingleton(env: ['staging', 'production'])
@DriftDatabase(tables: [CachedResponses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'scamshield'));

  @override
  int get schemaVersion => 1;
}