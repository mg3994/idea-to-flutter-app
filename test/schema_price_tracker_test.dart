import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_price_tracker.dart';

void main() {
  group('SchemaPriceTracker Tests', () {
    test('Calculates price drop percentage correctly', () {
      final delta = SchemaPriceTracker.calculatePriceDelta(
        oldPrice: 100.0,
        newPrice: 80.0,
      );

      expect(delta['difference'], -20.0);
      expect(delta['percentageChange'], -20.0);
      expect(delta['isPriceDropped'], isTrue);
    });

    test('Calculates price increase percentage correctly', () {
      final delta = SchemaPriceTracker.calculatePriceDelta(
        oldPrice: 100.0,
        newPrice: 125.0,
      );

      expect(delta['difference'], 25.0);
      expect(delta['percentageChange'], 25.0);
      expect(delta['isPriceDropped'], isFalse);
    });
  });
}
