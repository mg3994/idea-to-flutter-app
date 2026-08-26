import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_condition_checker.dart';

void main() {
  group('SchemaConditionChecker Tests', () {
    test('Parses RefurbishedCondition URL correctly', () {
      final schema = {
        'offers': {
          'itemCondition': 'https://schema.org/RefurbishedCondition',
        },
      };

      expect(SchemaConditionChecker.checkCondition(schema), ItemCondition.refurbishedCondition);
      expect(SchemaConditionChecker.formatConditionName(ItemCondition.refurbishedCondition), 'Refurbished');
    });

    test('Parses NewCondition string correctly', () {
      final schema = {
        'itemCondition': 'BrandNew',
      };

      expect(SchemaConditionChecker.checkCondition(schema), ItemCondition.newCondition);
      expect(SchemaConditionChecker.formatConditionName(ItemCondition.newCondition), 'Brand New');
    });
  });
}
