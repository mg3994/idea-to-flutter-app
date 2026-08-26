/// Utility engine for deep-merging variant schema JSON onto master schema JSON.
class SchemaOverride {
  /// Merges [overrideData] recursively on top of [baseData].
  static Map<String, dynamic> deepMerge({
    required Map<String, dynamic> baseData,
    required Map<String, dynamic> overrideData,
  }) {
    final Map<String, dynamic> result = Map<String, dynamic>.from(baseData);

    overrideData.forEach((key, overrideValue) {
      final baseValue = result[key];

      if (baseValue is Map<String, dynamic> && overrideValue is Map<String, dynamic>) {
        result[key] = deepMerge(
          baseData: baseValue,
          overrideData: overrideValue,
        );
      } else if (overrideValue is List && baseValue is List) {
        // If override lists elements, override replaces base list unless element level merge is needed.
        result[key] = overrideValue;
      } else if (overrideValue != null) {
        result[key] = overrideValue;
      }
    });

    return result;
  }
}
