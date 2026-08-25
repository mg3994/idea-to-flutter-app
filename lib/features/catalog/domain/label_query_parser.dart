/// Helper to parse label query expressions with space or | (OR) operators.
class LabelQueryParser {
  /// Parses filter query e.g. "label:electronics | label:mobile" or "electronics mobile"
  /// Returns a set of label query strings to match against post labels.
  static List<String> parse(String rawQuery) {
    if (rawQuery.trim().isEmpty) return [];

    String query = rawQuery.trim();
    if (query.startsWith('label:')) {
      query = query.substring(6);
    }

    final tokens = query
        .split(RegExp(r'[\|\s]+'))
        .map((s) => s.trim().replaceAll('label:', ''))
        .where((s) => s.isNotEmpty)
        .toList();

    return tokens;
  }

  /// Evaluates whether a post's label list matches the label query tokens.
  static bool matches(List<String> postLabels, String rawQuery) {
    final tokens = parse(rawQuery);
    if (tokens.isEmpty) return true;

    final normalizedPostLabels = postLabels.map((l) => l.trim().toLowerCase()).toList();

    return tokens.any((token) {
      final t = token.toLowerCase();
      return normalizedPostLabels.any((l) => l.contains(t));
    });
  }
}
