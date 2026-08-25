class SchemaAuditReport {
  final bool isValidProduct;
  final List<String> missingFields;
  final List<String> warnings;
  final int healthScorePercentage;

  SchemaAuditReport({
    required this.isValidProduct,
    required this.missingFields,
    required this.warnings,
    required this.healthScorePercentage,
  });
}

class SchemaAuditUtility {
  /// Audits a resolved JSON-LD schema map and returns a data quality health report
  static SchemaAuditReport audit(Map<String, dynamic> schema) {
    final missingFields = <String>[];
    final warnings = <String>[];
    int score = 100;

    if (schema['name'] == null) {
      missingFields.add('name');
      score -= 25;
    }

    final hasPrice = schema['price'] != null ||
        (schema['offers'] is Map && (schema['offers'] as Map)['price'] != null) ||
        (schema['offers'] is List && (schema['offers'] as List).isNotEmpty && (schema['offers'] as List).first['price'] != null);

    if (!hasPrice) {
      missingFields.add('price/offers.price');
      score -= 25;
    }

    if (schema['brand'] == null) {
      warnings.add('Missing "brand" field');
      score -= 10;
    }

    if (schema['image'] == null) {
      warnings.add('Missing "image" property');
      score -= 10;
    }

    if (schema['description'] == null) {
      warnings.add('Missing "description" property');
      score -= 10;
    }

    if (schema['sku'] == null) {
      warnings.add('Missing "sku" identifier');
      score -= 10;
    }

    if (schema['aggregateRating'] == null) {
      warnings.add('Missing "aggregateRating" reviews summary');
      score -= 10;
    }

    final isValidProduct = missingFields.isEmpty;
    final finalScore = score.clamp(0, 100);

    return SchemaAuditReport(
      isValidProduct: isValidProduct,
      missingFields: missingFields,
      warnings: warnings,
      healthScorePercentage: finalScore,
    );
  }
}
