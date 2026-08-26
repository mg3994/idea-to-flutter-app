import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';
import 'package:blog_store/features/catalog/domain/product_comparison_utility.dart';

void main() {
  group('ProductComparisonUtility Tests', () {
    test('Builds comparison matrix rows across products', () {
      final p1 = ProductEntity(
        id: 'p1',
        blogId: 'b1',
        title: 'Phone A',
        price: 500.0,
        labels: [],
        rawSchema: {},
        resolvedSchema: {'name': 'Phone A', 'ram': '8GB', 'price': '500.0'},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final p2 = ProductEntity(
        id: 'p2',
        blogId: 'b1',
        title: 'Phone B',
        price: 700.0,
        labels: [],
        rawSchema: {},
        resolvedSchema: {'name': 'Phone B', 'ram': '12GB', 'price': '700.0', '5g': 'Yes'},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final matrix = ProductComparisonUtility.buildMatrix([p1, p2]);

      expect(matrix.isNotEmpty, isTrue);

      final ramRow = matrix.firstWhere((r) => r.propertyKey == 'ram');
      expect(ramRow.productValues['p1'], '8GB');
      expect(ramRow.productValues['p2'], '12GB');

      final row5g = matrix.firstWhere((r) => r.propertyKey == '5g');
      expect(row5g.productValues['p1'], '-');
      expect(row5g.productValues['p2'], 'Yes');
    });
  });
}
