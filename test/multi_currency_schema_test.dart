import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';
import 'package:blog_store/shared/i18n/currency_converter.dart';

void main() {
  group('Multi-Currency Schema Parsing Tests', () {
    test('Parses INR currency from offers map', () {
      final postMap = {
        'id': 'inr_1',
        'title': 'Indian Smart TV',
        'content': '4K Smart TV',
        'published': '2025-01-01T00:00:00Z',
      };

      final resolvedSchema = {
        'name': 'Indian Smart TV',
        'offers': {
          'price': '14990.00',
          'priceCurrency': 'INR',
        },
      };

      final product = ProductEntity.fromPostMap(
        postMap: postMap,
        blogId: '1774904866501098696',
        resolvedSchema: resolvedSchema,
      );

      expect(product.price, 14990.00);
      expect(product.currency, 'INR');

      final formattedUsd = CurrencyConverter.format(
        price: product.price,
        fromCurrency: product.currency,
        targetCurrency: 'USD',
      );
      expect(formattedUsd, '\$179.52');
    });

    test('Parses EUR currency from top-level priceCurrency node', () {
      final postMap = {
        'id': 'eur_1',
        'title': 'Euro Espresso Machine',
        'content': 'Espresso Machine',
        'published': '2025-01-01T00:00:00Z',
      };

      final resolvedSchema = {
        'name': 'Euro Espresso Machine',
        'price': '89.99',
        'priceCurrency': 'EUR',
      };

      final product = ProductEntity.fromPostMap(
        postMap: postMap,
        blogId: '1774904866501098696',
        resolvedSchema: resolvedSchema,
      );

      expect(product.price, 89.99);
      expect(product.currency, 'EUR');

      final formattedEur = CurrencyConverter.format(
        price: product.price,
        fromCurrency: product.currency,
        targetCurrency: 'EUR',
      );
      expect(formattedEur, '€89.99');
    });
  });
}
