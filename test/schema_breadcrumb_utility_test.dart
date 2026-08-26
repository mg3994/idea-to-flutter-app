import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_breadcrumb_utility.dart';

void main() {
  group('SchemaBreadcrumbUtility Tests', () {
    test('Extracts and sorts BreadcrumbList items correctly', () {
      final schema = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        'breadcrumb': {
          '@type': 'BreadcrumbList',
          'itemListElement': [
            {
              '@type': 'ListItem',
              'position': 2,
              'item': {'@id': '/electronics/smartphones', 'name': 'Smartphones'},
            },
            {
              '@type': 'ListItem',
              'position': 1,
              'item': {'@id': '/electronics', 'name': 'Electronics'},
            },
          ],
        },
      };

      final breadcrumbs = SchemaBreadcrumbUtility.extractBreadcrumbs(schema);

      expect(breadcrumbs.length, 2);
      expect(breadcrumbs[0].name, 'Electronics');
      expect(breadcrumbs[0].position, 1);
      expect(breadcrumbs[1].name, 'Smartphones');
      expect(breadcrumbs[1].position, 2);
    });
  });
}
