import 'package:intl/intl.dart';

/// Resolves Schema.org `@value` and `@language` dynamic locale filtering and timestamp normalization.
class SchemaI18nResolver {
  /// Resolves a dynamic JSON-LD node that could be a String or dynamic array of `{"@value": ..., "@language": ...}`.
  static String resolveValue(dynamic node, {String locale = 'en'}) {
    if (node == null) return '';
    if (node is String) return node;

    if (node is List) {
      final targetLang = locale.toLowerCase().split('_').first;

      // 1. Exact match for language e.g. "en-US" or "en"
      for (final item in node) {
        if (item is Map) {
          final lang = item['@language']?.toString().toLowerCase();
          if (lang == locale.toLowerCase()) {
            return item['@value']?.toString() ?? '';
          }
        }
      }

      // 2. Partial match for primary language code e.g. "en"
      for (final item in node) {
        if (item is Map) {
          final lang = item['@language']?.toString().toLowerCase();
          if (lang != null && lang.startsWith(targetLang)) {
            return item['@value']?.toString() ?? '';
          }
        }
      }

      // 3. Fallback to first element with @value
      for (final item in node) {
        if (item is Map && item.containsKey('@value')) {
          return item['@value']?.toString() ?? '';
        }
        if (item is String) return item;
      }
    }

    if (node is Map) {
      if (node.containsKey('@value')) {
        return node['@value']?.toString() ?? '';
      }
    }

    return node.toString();
  }

  /// Normalizes ISO 8601 post timestamp string to formatted local device time.
  static String formatLocalTimestamp(String isoDateString, {String format = 'yyyy-MM-dd HH:mm'}) {
    if (isoDateString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoDateString).toLocal();
      return DateFormat(format).format(dateTime);
    } catch (_) {
      return isoDateString;
    }
  }
}
