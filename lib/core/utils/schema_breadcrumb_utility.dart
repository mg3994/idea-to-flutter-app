class BreadcrumbItem {
  final String name;
  final int position;
  final String? url;

  BreadcrumbItem({
    required this.name,
    required this.position,
    this.url,
  });
}

class SchemaBreadcrumbUtility {
  /// Extracts and parses Schema.org BreadcrumbList items from resolved schema
  static List<BreadcrumbItem> extractBreadcrumbs(Map<String, dynamic> schema) {
    final List<BreadcrumbItem> items = [];

    dynamic breadcrumbNode = schema['breadcrumb'] ?? schema['BreadcrumbList'];

    if (breadcrumbNode == null && schema['itemListElement'] != null) {
      breadcrumbNode = schema;
    }

    if (breadcrumbNode is Map<String, dynamic>) {
      final elements = breadcrumbNode['itemListElement'];
      if (elements is List) {
        for (int i = 0; i < elements.length; i++) {
          final el = elements[i];
          if (el is Map<String, dynamic>) {
            final name = _extractName(el['item'] ?? el['name']);
            final position = int.tryParse(el['position']?.toString() ?? '') ?? (i + 1);
            if (name.isNotEmpty) {
              items.add(BreadcrumbItem(name: name, position: position));
            }
          }
        }
      }
    }

    items.sort((a, b) => a.position.compareTo(b.position));
    return items;
  }

  static String _extractName(dynamic item) {
    if (item == null) return '';
    if (item is String) return item;
    if (item is Map) {
      return item['name']?.toString() ?? item['@id']?.toString() ?? '';
    }
    return '';
  }
}
