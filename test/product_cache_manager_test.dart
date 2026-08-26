import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:blog_store/features/cart_wishlist/data/app_database.dart';
import 'package:blog_store/features/cart_wishlist/data/product_cache_manager.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';

void main() {
  late AppDatabase database;
  late ProductCacheManager cacheManager;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    cacheManager = ProductCacheManager(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Caches and retrieves products in Drift DB', () async {
    final product = ProductEntity(
      id: 'cache_1',
      blogId: 'blog_1',
      title: 'Cached Wireless Earbuds',
      price: 49.99,
      labels: ['audio', 'wireless'],
      rawSchema: {'@type': 'Product', 'name': 'Earbuds'},
      resolvedSchema: {'@type': 'Product', 'name': 'Earbuds', 'price': 49.99},
      publishedAt: '2025-01-10T12:00:00Z',
    );

    await cacheManager.cacheProducts([product]);
    final retrieved = await cacheManager.getCachedProducts();

    expect(retrieved.length, 1);
    expect(retrieved.first.id, 'cache_1');
    expect(retrieved.first.title, 'Cached Wireless Earbuds');
    expect(retrieved.first.price, 49.99);
    expect(retrieved.first.labels, contains('audio'));
  });
}
