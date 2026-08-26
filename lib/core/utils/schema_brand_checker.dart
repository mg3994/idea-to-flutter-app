class BrandInfo {
  final String brandName;
  final String? logoUrl;
  final String? brandUrl;

  BrandInfo({
    required this.brandName,
    this.logoUrl,
    this.brandUrl,
  });
}

class SchemaBrandChecker {
  /// Parses Schema.org brand or organization from resolved schema
  static BrandInfo checkBrand(Map<String, dynamic> schema) {
    dynamic brandNode = schema['brand'] ?? schema['manufacturer'] ?? schema['organization'];

    if (brandNode is Map<String, dynamic>) {
      final name = brandNode['name']?.toString() ?? 'Antinna Brand';
      final logo = brandNode['logo']?.toString() ?? brandNode['image']?.toString();
      final url = brandNode['url']?.toString() ?? brandNode['@id']?.toString();
      return BrandInfo(
        brandName: name,
        logoUrl: logo,
        brandUrl: url,
      );
    } else if (brandNode is String && brandNode.isNotEmpty) {
      return BrandInfo(
        brandName: brandNode,
      );
    }

    return BrandInfo(
      brandName: 'Antinna',
    );
  }
}
