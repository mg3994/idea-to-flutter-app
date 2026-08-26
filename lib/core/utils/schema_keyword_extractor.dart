class SchemaKeywordExtractor {
  /// Tokenizes and extracts searchable keywords from resolved JSON-LD schema
  static Set<String> extractKeywords(Map<String, dynamic> schema) {
    final Set<String> keywords = {};

    void processNode(dynamic node) {
      if (node == null) return;

      if (node is String) {
        final tokens = node
            .toLowerCase()
            .replaceAll(RegExp(r'[^\w\s]'), ' ')
            .split(RegExp(r'\s+'))
            .where((t) => t.length > 1);
        keywords.addAll(tokens);
      } else if (node is List) {
        for (final item in node) {
          processNode(item);
        }
      } else if (node is Map<String, dynamic>) {
        node.forEach((key, value) {
          if (key == 'name' || key == 'brand' || key == 'sku' || key == 'category' || key == 'description' || key == 'color') {
            processNode(value);
          }
        });
      }
    }

    processNode(schema);
    return keywords;
  }
}
