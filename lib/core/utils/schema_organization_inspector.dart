class OrganizationInfo {
  final String legalName;
  final String? taxId;
  final String? vatId;

  OrganizationInfo({
    required this.legalName,
    this.taxId,
    this.vatId,
  });
}

class SchemaOrganizationInspector {
  /// Parses Schema.org legalName, vatID, or taxID from resolved schema
  static OrganizationInfo inspect(Map<String, dynamic> schema) {
    dynamic orgNode = schema['organization'] ?? schema['publisher'] ?? schema['provider'];

    if (orgNode is Map<String, dynamic>) {
      final name = orgNode['legalName']?.toString() ?? orgNode['name']?.toString() ?? 'Antinna Corp';
      final tax = orgNode['taxID']?.toString();
      final vat = orgNode['vatID']?.toString();
      return OrganizationInfo(legalName: name, taxId: tax, vatId: vat);
    }

    return OrganizationInfo(legalName: 'Antinna Technologies');
  }
}
