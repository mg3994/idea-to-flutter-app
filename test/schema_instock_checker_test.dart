import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_instock_checker.dart';

void main() {
  group('SchemaInStockChecker Tests', () {
    test('Parses InStock schema URL correctly', () {
      final schema = {
        'offers': {
          'availability': 'https://schema.org/InStock',
        },
      };

      expect(SchemaInStockChecker.checkAvailability(schema), StockStatus.inStock);
    });

    test('Parses OutOfStock schema URL correctly', () {
      final schema = {
        'offers': {
          'availability': 'https://schema.org/OutOfStock',
        },
      };

      expect(SchemaInStockChecker.checkAvailability(schema), StockStatus.outOfStock);
    });

    test('Parses PreOrder schema string correctly', () {
      final schema = {
        'availability': 'PreOrder',
      };

      expect(SchemaInStockChecker.checkAvailability(schema), StockStatus.preOrder);
    });
  });
}
