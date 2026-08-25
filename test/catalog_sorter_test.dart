import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';
import 'package:blog_store/features/catalog/domain/catalog_sorter.dart';

void main() {
  group('CatalogSorter Tests', () {
    final p1 = ProductEntity(
      id: '1',
      blogId: 'blog1',
      title: 'Budget Phone',
      price: 199.99,
      labels: ['phone'],
      rawSchema: {},
      resolvedSchema: {},
      publishedAt: '2025-01-01T10:00:00Z',
    );

    final p2 = ProductEntity(
      id: '2',
      blogId: 'blog1',
      title: 'Flagship Phone',
      price: 999.99,
      labels: ['phone'],
      rawSchema: {},
      resolvedSchema: {},
      publishedAt: '2025-02-01T10:00:00Z',
    );

    final p3 = ProductEntity(
      id: '3',
      blogId: 'blog1',
      title: 'Midrange Laptop',
      price: 599.99,
      labels: ['laptop'],
      rawSchema: {},
      resolvedSchema: {},
      publishedAt: '2025-01-15T10:00:00Z',
    );

    final products = [p1, p2, p3];

    test('Sorts price low to high', () {
      final sorted = CatalogSorter.sort(products, SortOption.priceLowToHigh);
      expect(sorted.map((p) => p.id), ['1', '3', '2']);
    });

    test('Sorts price high to low', () {
      final sorted = CatalogSorter.sort(products, SortOption.priceHighToLow);
      expect(sorted.map((p) => p.id), ['2', '3', '1']);
    });

    test('Sorts by newest published date', () {
      final sorted = CatalogSorter.sort(products, SortOption.newest);
      expect(sorted.map((p) => p.id), ['2', '3', '1']);
    });
  });
}
