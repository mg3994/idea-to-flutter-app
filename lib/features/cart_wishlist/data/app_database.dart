import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CartItems extends Table {
  TextColumn get id => text()();
  TextColumn get postId => text()();
  TextColumn get blogId => text()();
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get schemaJson => text()(); // Serialized raw/resolved JSON-LD schema
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKeys => {id};
}

class WishlistItems extends Table {
  TextColumn get id => text()();
  TextColumn get postId => text()();
  TextColumn get blogId => text()();
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get schemaJson => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKeys => {id};
}

class CachedProducts extends Table {
  TextColumn get id => text()();
  TextColumn get blogId => text()();
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get rawSchemaJson => text()();
  TextColumn get resolvedSchemaJson => text()();
  TextColumn get labelsJson => text()();
  TextColumn get publishedAt => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKeys => {id};
}

class OrderRecords extends Table {
  TextColumn get orderId => text()();
  TextColumn get userId => text()();
  RealColumn get totalAmount => real()();
  TextColumn get paymentMethod => text()();
  TextColumn get itemsJson => text()();
  TextColumn get shippingAddressJson => text()();
  TextColumn get status => text().withDefault(const Constant('PLACED'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKeys => {orderId};
}

class QueuedOrders extends Table {
  TextColumn get queueId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKeys => {queueId};
}

@DriftDatabase(tables: [CartItems, WishlistItems, CachedProducts, OrderRecords, QueuedOrders])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'blog_store_db');
  }
}
