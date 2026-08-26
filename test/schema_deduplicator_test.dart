import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';
import 'package:blog_store/core/utils/schema_deduplicator.dart';

void main() {
  group('SchemaDeduplicator Tests', () {
    test('Deduplicates products with identical @id', () {
      final p1 = ProductEntity(
        id: 'post_1',
        blogId: 'blog_1',
        title: 'Smartphone Master',
        price: 899.0,
        labels: [],
        rawSchema: {'@id': 'canonical_phone_1'},
        resolvedSchema: {'@id': 'canonical_phone_1', 'name': 'Smartphone Master'},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final p2 = ProductEntity(
        id: 'post_2',
        blogId: 'blog_1',
        title: 'Smartphone Master Duplicate',
        price: 899.0,
        labels: [],
        rawSchema: {'@id': 'canonical_phone_1'},
        resolvedSchema: {'@id': 'canonical_phone_1', 'name': 'Smartphone Master'},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final deduplicated = SchemaDeduplicator.deduplicate([p1, p2]);

      expect(deduplicated.length, 1);
      expect(deduplicated.first.id, 'post_1');
    });

    test('Deduplicates products with identical post ID and blog ID', () {
      final p1 = ProductEntity(
        id: 'post_100',
        blogId: 'blog_100',
        title: 'Wireless Headphones',
        price: 150.0,
        labels: [],
        rawSchema: {},
        resolvedSchema: {},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final p2 = ProductEntity(
        id: 'post_100',
        blogId: 'blog_100',
        title: 'Wireless Headphones Dup',
        price: 150.0,
        labels: [],
        rawSchema: {},
        resolvedSchema: {},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final deduplicated = SchemaDeduplicator.deduplicate([p1, p2]);

      expect(deduplicated.length, 1);
      expect(deduplicated.first.title, 'Wireless Headphones');
    });
  });
}
