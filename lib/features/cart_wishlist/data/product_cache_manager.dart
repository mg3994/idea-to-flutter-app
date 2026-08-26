import 'dart:convert';
import 'package:drift/drift.dart';
import '../../catalog/domain/product_entity.dart';
import 'app_database.dart';

class ProductCacheManager {
  final AppDatabase database;

  ProductCacheManager({required this.database});

  /// Saves products to local Drift database for offline browsing.
  Future<void> cacheProducts(List<ProductEntity> products) async {
    for (final p in products) {
      await database.into(database.cachedProducts).insertOnConflictUpdate(
            CachedProductsCompanion.insert(
              id: p.id,
              blogId: p.blogId,
              title: p.title,
              price: p.price,
              currency: Value(p.currency),
              imageUrl: Value(p.imageUrl),
              rawSchemaJson: jsonEncode(p.rawSchema),
              resolvedSchemaJson: jsonEncode(p.resolvedSchema),
              labelsJson: jsonEncode(p.labels),
              publishedAt: p.publishedAt,
            ),
          );
    }
  }

  /// Retrieves cached products from Drift database.
  Future<List<ProductEntity>> getCachedProducts() async {
    final cached = await database.select(database.cachedProducts).get();
    return cached.map((c) {
      final Map<String, dynamic> rawSchema = jsonDecode(c.rawSchemaJson) as Map<String, dynamic>;
      final Map<String, dynamic> resolvedSchema = jsonDecode(c.resolvedSchemaJson) as Map<String, dynamic>;
      final List<String> labels = List<String>.from(jsonDecode(c.labelsJson) as List);

      return ProductEntity(
        id: c.id,
        blogId: c.blogId,
        title: c.title,
        price: c.price,
        currency: c.currency,
        imageUrl: c.imageUrl,
        labels: labels,
        rawSchema: rawSchema,
        resolvedSchema: resolvedSchema,
        areaServed: resolvedSchema['areaServed'],
        publishedAt: c.publishedAt,
      );
    }).toList();
  }
}
