import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';
import 'package:blog_store/features/catalog/domain/schema_group_aggregator.dart';

void main() {
  group('SchemaGroupAggregator Tests', () {
    test('Groups variant products by @base master post anchor', () {
      final master = ProductEntity(
        id: 'master_1',
        blogId: '1774904866501098696',
        title: 'Master Laptop',
        price: 1000.0,
        labels: [],
        rawSchema: {'@id': '1774904866501098696/master_1'},
        resolvedSchema: {},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final var1 = ProductEntity(
        id: 'var_1',
        blogId: '1774904866501098696',
        title: 'Variant Laptop 16GB',
        price: 1200.0,
        labels: [],
        rawSchema: {'@base': '1774904866501098696/master_1'},
        resolvedSchema: {},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final var2 = ProductEntity(
        id: 'var_2',
        blogId: '1774904866501098696',
        title: 'Variant Laptop 32GB',
        price: 1500.0,
        labels: [],
        rawSchema: {'@base': '1774904866501098696/master_1'},
        resolvedSchema: {},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final groups = SchemaGroupAggregator.aggregate([master, var1, var2]);

      expect(groups.length, 1);
      expect(groups.first.masterId, '1774904866501098696/master_1');
      expect(groups.first.masterProduct, isNotNull);
      expect(groups.first.masterProduct!.id, 'master_1');
      expect(groups.first.variants.length, 2);
    });
  });
}
