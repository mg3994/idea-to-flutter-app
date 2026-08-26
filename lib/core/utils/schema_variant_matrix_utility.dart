class SchemaVariantMatrixUtility {
  /// Compares variant schema JSON against base master schema JSON and extracts explicitly overridden key-value pairs
  static Map<String, dynamic> extractDelta({
    required Map<String, dynamic> masterSchema,
    required Map<String, dynamic> variantSchema,
  }) {
    final Map<String, dynamic> delta = {};

    variantSchema.forEach((key, variantValue) {
      if (key == '@base' || key == '@context') return;

      final masterValue = masterSchema[key];

      if (masterValue == null) {
        // Brand new key added in variant
        delta[key] = variantValue;
      } else if (variantValue is Map<String, dynamic> && masterValue is Map<String, dynamic>) {
        final nestedDelta = extractDelta(
          masterSchema: masterValue,
          variantSchema: variantValue,
        );
        if (nestedDelta.isNotEmpty) {
          delta[key] = nestedDelta;
        }
      } else if (variantValue != masterValue) {
        // Explicit value override
        delta[key] = variantValue;
      }
    });

    return delta;
  }
}
