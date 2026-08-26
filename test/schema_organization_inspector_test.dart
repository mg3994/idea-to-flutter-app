import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_organization_inspector.dart';

void main() {
  group('SchemaOrganizationInspector Tests', () {
    test('Parses legalName, vatID, and taxID correctly', () {
      final schema = {
        'organization': {
          'legalName': 'Antinna Global Solutions Pvt Ltd',
          'taxID': 'TAX-998877',
          'vatID': 'VAT-112233',
        },
      };

      final info = SchemaOrganizationInspector.inspect(schema);

      expect(info.legalName, 'Antinna Global Solutions Pvt Ltd');
      expect(info.taxId, 'TAX-998877');
      expect(info.vatId, 'VAT-112233');
    });
  });
}
