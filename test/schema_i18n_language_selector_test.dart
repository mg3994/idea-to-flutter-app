import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/shared/i18n/schema_i18n_language_selector.dart';

void main() {
  group('SchemaI18nLanguageSelector Tests', () {
    test('Extracts unique @language codes from dynamic schema nodes', () {
      final multiLangNode = [
        {'@value': 'Smartphone Pro', '@language': 'en'},
        {'@value': 'Teléfono Inteligente Pro', '@language': 'es'},
        {'@value': 'Smartphone Pro FR', '@language': 'fr'},
      ];

      final langs = SchemaI18nLanguageSelector.extractAvailableLanguages(multiLangNode);

      expect(langs.length, 3);
      expect(langs, contains('en'));
      expect(langs, contains('es'));
      expect(langs, contains('fr'));
    });
  });
}
