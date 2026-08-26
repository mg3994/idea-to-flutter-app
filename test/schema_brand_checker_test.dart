import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_brand_checker.dart';

void main() {
  group('SchemaBrandChecker Tests', () {
    test('Parses brand Map node correctly', () {
      final schema = {
        'brand': {
          '@type': 'Brand',
          'name': 'Antinna Tech',
          'logo': 'https://antinna.in/logo.png',
        },
      };

      final info = SchemaBrandChecker.checkBrand(schema);

      expect(info.brandName, 'Antinna Tech');
      expect(info.logoUrl, 'https://antinna.in/logo.png');
    });

    test('Parses brand String node correctly', () {
      final schema = {
        'brand': 'Antinna Mobile',
      };

      final info = SchemaBrandChecker.checkBrand(schema);

      expect(info.brandName, 'Antinna Mobile');
    });
  });
}
