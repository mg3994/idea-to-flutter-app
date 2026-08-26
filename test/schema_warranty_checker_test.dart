import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_warranty_checker.dart';

void main() {
  group('SchemaWarrantyChecker Tests', () {
    test('Parses warranty Map node correctly', () {
      final schema = {
        'hasWarranty': {
          'name': 'Extended Guarantee',
          'duration': '2 Years',
        },
      };

      final info = SchemaWarrantyChecker.checkWarranty(schema);

      expect(info.hasWarranty, isTrue);
      expect(info.warrantyText, contains('Extended Guarantee'));
      expect(info.warrantyText, contains('2 Years'));
    });

    test('Parses warranty String node correctly', () {
      final schema = {
        'offers': {
          'warranty': '3-Year Limited Warranty',
        },
      };

      final info = SchemaWarrantyChecker.checkWarranty(schema);

      expect(info.hasWarranty, isTrue);
      expect(info.warrantyText, '3-Year Limited Warranty');
    });
  });
}
