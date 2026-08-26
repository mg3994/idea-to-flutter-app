import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_aggregate_offer_checker.dart';

void main() {
  group('SchemaAggregateOfferChecker Tests', () {
    test('Parses AggregateOffer node lowPrice, highPrice, and offerCount correctly', () {
      final schema = {
        'offers': {
          '@type': 'AggregateOffer',
          'lowPrice': '199.00',
          'highPrice': '299.00',
          'offerCount': '5',
          'priceCurrency': 'USD',
        },
      };

      final info = SchemaAggregateOfferChecker.checkAggregateOffer(schema);

      expect(info.isAggregate, isTrue);
      expect(info.lowPrice, 199.00);
      expect(info.highPrice, 299.00);
      expect(info.offerCount, 5);
      expect(info.currency, 'USD');
    });
  });
}
