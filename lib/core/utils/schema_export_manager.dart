import 'dart:convert';

class SchemaExportManager {
  /// Formats resolved schema JSON-LD map into pretty-printed string for export or clipboard copy
  static String formatJsonLd(Map<String, dynamic> schema) {
    return const JsonEncoder.withIndent('  ').convert(schema);
  }

  /// Generates HTML microdata snippet embedding the application/ld+json script tag
  static String generateHtmlMicrodataSnippet(Map<String, dynamic> schema) {
    final jsonStr = formatJsonLd(schema);
    return '<script type="application/ld+json">\n$jsonStr\n</script>';
  }
}
