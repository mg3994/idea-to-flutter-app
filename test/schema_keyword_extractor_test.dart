import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_keyword_extractor.dart';

void main() {
  group('SchemaKeywordExtractor Tests', () {
    test('Tokenizes and extracts keywords from JSON-LD schema properties', () {
      final schema = {
        'name': 'Flagship Smartphone Pro 5G',
        'brand': {'@type': 'Brand', 'name': 'Antinna'},
        'sku': 'ANT-5G-PRO',
        'color': 'Midnight Blue',
      };

      final keywords = SchemaKeywordExtractor.extractKeywords(schema);

      expect(keywords, contains('flagship'));
      expect(keywords, contains('smartphone'));
      expect(keywords, contains('antinna'));
      expect(keywords, contains('midnight'));
      expect(keywords, contains('blue'));
    });
  });
}
