import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/batch_schema_extractor.dart';

void main() {
  group('BatchSchemaExtractor Tests', () {
    test('Extracts multiple application/ld+json script blocks from HTML', () {
      final html = '''
        <html>
          <head>
            <script type="application/ld+json">
              {"@type": "Organization", "name": "Antinna"}
            </script>
            <script type="application/ld+json">
              {"@type": "Product", "name": "Multi-Script Phone", "price": "299.00"}
            </script>
          </head>
        </html>
      ''';

      final schemas = BatchSchemaExtractor.extractAll(html);

      expect(schemas.length, 2);
      expect(schemas[0]['name'], 'Antinna');
      expect(schemas[1]['name'], 'Multi-Script Phone');
    });

    test('Extracts schemas embedded inside @graph array', () {
      final html = '''
        <script type="application/ld+json">
          {
            "@context": "https://schema.org",
            "@graph": [
              {"@type": "Product", "name": "Graph Item 1"},
              {"@type": "Product", "name": "Graph Item 2"}
            ]
          }
        </script>
      ''';

      final schemas = BatchSchemaExtractor.extractAll(html);

      expect(schemas.length, 2);
      expect(schemas[0]['name'], 'Graph Item 1');
      expect(schemas[1]['name'], 'Graph Item 2');
    });
  });
}
