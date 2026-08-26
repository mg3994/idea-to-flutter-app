import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_return_policy_checker.dart';

void main() {
  group('SchemaReturnPolicyChecker Tests', () {
    test('Parses 30-day merchant return policy map correctly', () {
      final schema = {
        'hasMerchantReturnPolicy': {
          '@type': 'MerchantReturnPolicy',
          'returnPolicyCategory': 'https://schema.org/MerchantReturnFinancing',
          'merchantReturnDays': 30,
        },
      };

      final info = SchemaReturnPolicyChecker.checkReturnPolicy(schema);

      expect(info.isReturnable, isTrue);
      expect(info.categoryName, '30-Day Returns');
      expect(info.returnWindowDays, 30);
    });

    test('Parses Non-Returnable policy category correctly', () {
      final schema = {
        'hasMerchantReturnPolicy': {
          'returnPolicyCategory': 'https://schema.org/MerchantReturnNotPermitted',
        },
      };

      final info = SchemaReturnPolicyChecker.checkReturnPolicy(schema);

      expect(info.isReturnable, isFalse);
      expect(info.categoryName, 'Non-Returnable');
    });
  });
}
