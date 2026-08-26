class WarrantyInfo {
  final bool hasWarranty;
  final String warrantyText;

  WarrantyInfo({
    required this.hasWarranty,
    required this.warrantyText,
  });
}

class SchemaWarrantyChecker {
  /// Parses Schema.org hasWarranty or warranty from resolved schema
  static WarrantyInfo checkWarranty(Map<String, dynamic> schema) {
    dynamic warrantyNode = schema['hasWarranty'] ?? schema['warranty'];

    if (warrantyNode == null && schema['offers'] != null) {
      final offers = schema['offers'];
      if (offers is Map) {
        warrantyNode = offers['hasWarranty'] ?? offers['warranty'];
      } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
        warrantyNode = offers.first['hasWarranty'] ?? offers.first['warranty'];
      }
    }

    if (warrantyNode is Map<String, dynamic>) {
      final duration = warrantyNode['durationOfWarranty']?['value']?.toString() ??
          warrantyNode['duration']?.toString() ??
          '1 Year';
      final name = warrantyNode['name']?.toString() ?? 'Manufacturer Warranty';
      return WarrantyInfo(
        hasWarranty: true,
        warrantyText: '$name ($duration)',
      );
    } else if (warrantyNode is String && warrantyNode.isNotEmpty) {
      return WarrantyInfo(
        hasWarranty: true,
        warrantyText: warrantyNode,
      );
    }

    return WarrantyInfo(
      hasWarranty: true,
      warrantyText: '1-Year Standard Warranty',
    );
  }
}
