import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_audit_utility.dart';

void main() {
  group('SchemaAuditUtility Tests', () {
    test('Calculates 100% health score for complete schema', () {
      final completeSchema = {
        'name': 'Complete Smartphone',
        'price': '999.00',
        'brand': 'Acme',
        'image': 'https://example.com/img.jpg',
        'description': 'Full specs',
        'sku': 'SKU-100',
        'aggregateRating': {'ratingValue': '4.5'},
      };

      final report = SchemaAuditUtility.audit(completeSchema);

      expect(report.isValidProduct, isTrue);
      expect(report.healthScorePercentage, 100);
      expect(report.missingFields.isEmpty, isTrue);
      expect(report.warnings.isEmpty, isTrue);
    });

    test('Identifies missing required fields and calculates score penalty', () {
      final incompleteSchema = {
        'brand': 'Acme',
      };

      final report = SchemaAuditUtility.audit(incompleteSchema);

      expect(report.isValidProduct, isFalse);
      expect(report.missingFields, contains('name'));
      expect(report.missingFields, contains('price/offers.price'));
      expect(report.healthScorePercentage, lessThan(100));
    });
  });
}
