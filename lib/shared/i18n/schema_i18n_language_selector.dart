class SchemaI18nLanguageSelector {
  /// Extracts all unique @language codes present in dynamic Schema.org node arrays
  static Set<String> extractAvailableLanguages(dynamic node) {
    final Set<String> languages = {};

    if (node is List) {
      for (final item in node) {
        if (item is Map && item['@language'] != null) {
          languages.add(item['@language'].toString());
        }
      }
    } else if (node is Map && node['@language'] != null) {
      languages.add(node['@language'].toString());
    }

    return languages;
  }
}
