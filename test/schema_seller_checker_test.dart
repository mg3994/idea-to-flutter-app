import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_seller_checker.dart';

void main() {
  group('SchemaSellerChecker Tests', () {
    test('Parses seller Map node correctly', () {
      final schema = {
        'seller': {
          '@type': 'Organization',
          'name': 'Antinna Electronics Ltd',
          'url': 'https://antinna.in',
        },
      };

      final info = SchemaSellerChecker.checkSeller(schema);

      expect(info.isVerifiedMerchant, isTrue);
      expect(info.sellerName, 'Antinna Electronics Ltd');
      expect(info.sellerUrl, 'https://antinna.in');
    });

    test('Parses seller String node correctly', () {
      final schema = {
        'offers': {
          'seller': 'Official Store',
        },
      };

      final info = SchemaSellerChecker.checkSeller(schema);

      expect(info.isVerifiedMerchant, isTrue);
      expect(info.sellerName, 'Official Store');
    });
  });
}
