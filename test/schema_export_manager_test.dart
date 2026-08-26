import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_export_manager.dart';

void main() {
  group('SchemaExportManager Tests', () {
    test('Pretty prints JSON-LD schema map', () {
      final schema = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        'name': 'Exportable Smartphone',
        'price': '499.00',
      };

      final formatted = SchemaExportManager.formatJsonLd(schema);
      expect(formatted, contains('"@context": "https://schema.org"'));
      expect(formatted, contains('"name": "Exportable Smartphone"'));
    });

    test('Generates valid HTML script microdata snippet', () {
      final schema = {
        '@type': 'Product',
        'name': 'Exportable Item',
      };

      final snippet = SchemaExportManager.generateHtmlMicrodataSnippet(schema);
      expect(snippet, startsWith('<script type="application/ld+json">'));
      expect(snippet, endsWith('</script>'));
      expect(snippet, contains('"name": "Exportable Item"'));
    });
  });
}
