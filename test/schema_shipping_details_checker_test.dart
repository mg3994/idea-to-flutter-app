import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_shipping_details_checker.dart';

void main() {
  group('SchemaShippingDetailsChecker Tests', () {
    test('Parses free shipping details map correctly', () {
      final schema = {
        'shippingDetails': {
          '@type': 'OfferShippingDetails',
          'shippingRate': {
            'value': '0.00',
            'currency': 'USD',
          },
        },
      };

      final info = SchemaShippingDetailsChecker.checkShippingDetails(schema);

      expect(info.isFreeShipping, isTrue);
      expect(info.shippingRate, 0.0);
      expect(info.deliveryWindowText, contains('Free'));
    });

    test('Parses paid shipping rate correctly', () {
      final schema = {
        'shippingDetails': {
          'shippingRate': {
            'value': '15.00',
            'currency': 'EUR',
          },
          'deliveryTime': {
            'handlingTime': {'value': 2},
          },
        },
      };

      final info = SchemaShippingDetailsChecker.checkShippingDetails(schema);

      expect(info.isFreeShipping, isFalse);
      expect(info.shippingRate, 15.0);
      expect(info.currency, 'EUR');
    });
  });
}
