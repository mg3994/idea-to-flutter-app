import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/checkout/domain/promo_code_engine.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';

void main() {
  group('PromoCodeEngine Tests', () {
    test('Calculates SAVE10 promo correctly', () {
      final res = PromoCodeEngine.evaluate(code: 'SAVE10', cartTotal: 100.0);
      expect(res.isValid, isTrue);
      expect(res.discountAmount, 10.0);
    });

    test('Calculates WELCOME50 promo correctly', () {
      final res = PromoCodeEngine.evaluate(code: 'WELCOME50', cartTotal: 200.0);
      expect(res.isValid, isTrue);
      expect(res.discountAmount, 100.0);
    });

    test('Handles invalid promo code', () {
      final res = PromoCodeEngine.evaluate(code: 'INVALID_CODE', cartTotal: 100.0);
      expect(res.isValid, isFalse);
      expect(res.discountAmount, 0.0);
    });
  });

  group('AggregateRating Schema Parsing Tests', () {
    test('Parses aggregateRating and reviews from JSON-LD schema', () {
      final postMap = {
        'id': 'post_rating_1',
        'title': 'Rated Product',
        'content': 'Product with ratings',
        'published': '2025-01-01T00:00:00Z',
      };

      final resolvedSchema = {
        'name': 'Rated Product',
        'price': '150.0',
        'aggregateRating': {
          'ratingValue': '4.8',
          'reviewCount': '24',
        },
        'review': [
          {
            'author': {'name': 'Alice'},
            'reviewBody': 'Great quality product!',
          }
        ],
      };

      final product = ProductEntity.fromPostMap(
        postMap: postMap,
        blogId: '1774904866501098696',
        resolvedSchema: resolvedSchema,
      );

      expect(product.ratingValue, 4.8);
      expect(product.reviewCount, 24);
      expect(product.reviews.length, 1);
      expect(product.reviews.first['author']['name'], 'Alice');
    });
  });
}
