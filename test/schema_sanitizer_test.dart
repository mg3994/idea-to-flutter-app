import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_sanitizer.dart';

void main() {
  group('SchemaSanitizer Tests', () {
    test('Strips HTML tags from descriptions', () {
      final html = '<p>This is a <b>great</b> product with <a href="#">features</a>.</p>';
      final clean = SchemaSanitizer.sanitizeDescription(html);

      expect(clean, 'This is a great product with features.');
    });

    test('Sanitizes prices formatted with currency symbols or string numbers', () {
      expect(SchemaSanitizer.sanitizePrice('\$1,299.99'), 1299.99);
      expect(SchemaSanitizer.sanitizePrice('€49.50'), 49.50);
      expect(SchemaSanitizer.sanitizePrice(199.99), 199.99);
      expect(SchemaSanitizer.sanitizePrice(null), 0.0);
    });
  });
}
