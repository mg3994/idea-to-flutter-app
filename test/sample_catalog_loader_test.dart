import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/config/sample_catalog_loader.dart';

void main() {
  group('SampleCatalogLoader Tests', () {
    test('Loads sample products with master and multi-currency variant schemas', () {
      final samples = SampleCatalogLoader.getSampleProducts();

      expect(samples.length, 3);

      final master = samples.firstWhere((p) => p.id == 'master_phone_1');
      expect(master.currency, 'USD');
      expect(master.price, 899.00);
      expect(master.ratingValue, 4.8);

      final variantInr = samples.firstWhere((p) => p.id == 'var_phone_inr');
      expect(variantInr.currency, 'INR');
      expect(variantInr.price, 69999.00);

      final variantEur = samples.firstWhere((p) => p.id == 'var_phone_eur');
      expect(variantEur.currency, 'EUR');
      expect(variantEur.price, 799.00);
    });
  });
}
