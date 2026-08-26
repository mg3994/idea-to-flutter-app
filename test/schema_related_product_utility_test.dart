import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';
import 'package:blog_store/features/catalog/domain/schema_related_product_utility.dart';

void main() {
  group('SchemaRelatedProductUtility Tests', () {
    test('Calculates related product score based on brand, labels, and price proximity', () {
      final current = ProductEntity(
        id: 'p1',
        blogId: 'b1',
        title: 'Antinna Phone X',
        price: 500.0,
        brand: 'Antinna',
        labels: ['mobile', 'electronics'],
        rawSchema: {},
        resolvedSchema: {},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final relatedSameBrand = ProductEntity(
        id: 'p2',
        blogId: 'b1',
        title: 'Antinna Phone Y',
        price: 520.0,
        brand: 'Antinna',
        labels: ['mobile'],
        rawSchema: {},
        resolvedSchema: {},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final unrelated = ProductEntity(
        id: 'p3',
        blogId: 'b1',
        title: 'Generic Washing Machine',
        price: 2000.0,
        brand: 'OtherBrand',
        labels: ['appliance'],
        rawSchema: {},
        resolvedSchema: {},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final related = SchemaRelatedProductUtility.getRelatedProducts(
        currentProduct: current,
        allProducts: [current, relatedSameBrand, unrelated],
      );

      expect(related.length, 1);
      expect(related.first.id, 'p2');
    });
  });
}
