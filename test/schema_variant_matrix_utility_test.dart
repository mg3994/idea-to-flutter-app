import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_variant_matrix_utility.dart';

void main() {
  group('SchemaVariantMatrixUtility Tests', () {
    test('Extracts explicit overrides delta between master and variant schema JSONs', () {
      final masterSchema = {
        'name': 'Master Phone 5G',
        'price': '899.00',
        'color': 'Black',
        'brand': 'Antinna',
      };

      final variantSchema = {
        '@base': '1774904866501098696/master_phone_1',
        'name': 'Variant Phone Red Edition',
        'price': '949.00',
        'color': 'Red',
      };

      final delta = SchemaVariantMatrixUtility.extractDelta(
        masterSchema: masterSchema,
        variantSchema: variantSchema,
      );

      expect(delta.containsKey('@base'), isFalse);
      expect(delta['name'], 'Variant Phone Red Edition');
      expect(delta['price'], '949.00');
      expect(delta['color'], 'Red');
      expect(delta.containsKey('brand'), isFalse); // Inherited without change
    });
  });
}
