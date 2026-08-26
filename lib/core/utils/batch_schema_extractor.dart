import 'dart:convert';

class BatchSchemaExtractor {
  /// Extracts all JSON-LD schema blocks from HTML content, including multiple <script> tags and @graph lists
  static List<Map<String, dynamic>> extractAll(String htmlContent) {
    final List<Map<String, dynamic>> results = [];

    final RegExp regExp = RegExp(
      r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>',
      multiLine: true,
      caseSensitive: false,
      dotAll: true,
    );

    final matches = regExp.allMatches(htmlContent);

    for (final match in matches) {
      final jsonString = match.group(1);
      if (jsonString == null || jsonString.trim().isEmpty) continue;

      final cleaned = jsonString
          .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
          .trim();

      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is Map<String, dynamic>) {
          if (decoded['@graph'] is List) {
            final graph = decoded['@graph'] as List;
            for (final item in graph) {
              if (item is Map<String, dynamic>) {
                results.add(item);
              }
            }
          } else {
            results.add(decoded);
          }
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              results.add(item);
            }
          }
        }
      } catch (_) {}
    }

    return results;
  }
}
