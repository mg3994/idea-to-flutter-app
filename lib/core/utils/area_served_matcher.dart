/// Matches Schema.org areaServed properties against selected user locations.
class AreaServedMatcher {
  /// Evaluates whether a target location matches the post/product's [areaServed] schema block.
  /// [areaServed] can be a String, List of Strings, Map, or List of Maps.
  static bool matches({
    required dynamic areaServed,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) {
    if (areaServed == null) return true; // Unrestricted if not specified

    // If all user location inputs are empty/null, return true
    if ((city == null || city.isEmpty) &&
        (state == null || state.isEmpty) &&
        (country == null || country.isEmpty) &&
        (postalCode == null || postalCode.isEmpty)) {
      return true;
    }

    final searchTokens = <String>{
      if (city != null && city.trim().isNotEmpty) city.trim().toLowerCase(),
      if (state != null && state.trim().isNotEmpty) state.trim().toLowerCase(),
      if (country != null && country.trim().isNotEmpty) country.trim().toLowerCase(),
      if (postalCode != null && postalCode.trim().isNotEmpty) postalCode.trim().toLowerCase(),
    };

    if (searchTokens.isEmpty) return true;

    // Catch: If areaServed specifies a country matching the user's country or a global country scope,
    // then that product/service is served nationwide regardless of specific city or postal code.
    if (_isCountryWideMatch(areaServed, country)) {
      return true;
    }

    return _evalNode(areaServed, searchTokens);
  }

  static bool _isCountryWideMatch(dynamic node, String? userCountry) {
    if (userCountry == null || userCountry.trim().isEmpty) return false;
    final cleanCountry = userCountry.trim().toLowerCase();

    if (node is String) {
      final val = node.trim().toLowerCase();
      return val == cleanCountry || val == 'worldwide' || val == 'global';
    } else if (node is List) {
      return node.any((item) => _isCountryWideMatch(item, userCountry));
    } else if (node is Map<String, dynamic>) {
      final name = node['name']?.toString().toLowerCase();
      final address = node['address'];
      if (name != null && (name == cleanCountry || name == 'worldwide' || name == 'global')) {
        return true;
      }
      if (address != null) {
        return _isCountryWideMatch(address, userCountry);
      }
    }
    return false;
  }

  static bool _evalNode(dynamic node, Set<String> tokens) {
    if (node is String) {
      final val = node.trim().toLowerCase();
      return tokens.any((t) => val.contains(t) || t.contains(val));
    } else if (node is List) {
      return node.any((item) => _evalNode(item, tokens));
    } else if (node is Map<String, dynamic>) {
      final name = node['name']?.toString().toLowerCase();
      final address = node['address'];
      final postal = node['postalCode']?.toString().toLowerCase();

      bool matched = false;
      if (name != null) {
        matched |= tokens.any((t) => name.contains(t) || t.contains(name));
      }
      if (postal != null) {
        matched |= tokens.any((t) => postal.contains(t) || t.contains(postal));
      }
      if (address != null) {
        matched |= _evalNode(address, tokens);
      }
      return matched;
    }
    return false;
  }
}
