class ReturnPolicyInfo {
  final bool isReturnable;
  final String categoryName;
  final int? returnWindowDays;
  final String? policyUrl;

  ReturnPolicyInfo({
    required this.isReturnable,
    required this.categoryName,
    this.returnWindowDays,
    this.policyUrl,
  });
}

class SchemaReturnPolicyChecker {
  /// Parses Schema.org hasMerchantReturnPolicy or returnPolicyCategory from resolved schema
  static ReturnPolicyInfo checkReturnPolicy(Map<String, dynamic> schema) {
    dynamic policyNode = schema['hasMerchantReturnPolicy'] ?? schema['returnPolicy'];

    if (policyNode == null && schema['offers'] != null) {
      final offers = schema['offers'];
      if (offers is Map) {
        policyNode = offers['hasMerchantReturnPolicy'] ?? offers['returnPolicy'];
      } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
        policyNode = offers.first['hasMerchantReturnPolicy'] ?? offers.first['returnPolicy'];
      }
    }

    if (policyNode == null) {
      return ReturnPolicyInfo(
        isReturnable: true,
        categoryName: 'Standard Return Policy',
      );
    }

    if (policyNode is Map<String, dynamic>) {
      final category = policyNode['returnPolicyCategory']?.toString().toLowerCase() ?? '';
      final window = int.tryParse(policyNode['merchantReturnDays']?.toString() ?? '');
      final url = policyNode['merchantReturnLink']?.toString() ?? policyNode['url']?.toString();

      final notPermitted = category.contains('notpermitted') || category.contains('noreturn');

      return ReturnPolicyInfo(
        isReturnable: !notPermitted,
        categoryName: notPermitted ? 'Non-Returnable' : (window != null ? '$window-Day Returns' : 'Returnable'),
        returnWindowDays: window,
        policyUrl: url,
      );
    }

    final val = policyNode.toString().toLowerCase();
    final notPermitted = val.contains('notpermitted') || val.contains('noreturn');

    return ReturnPolicyInfo(
      isReturnable: !notPermitted,
      categoryName: notPermitted ? 'Non-Returnable' : 'Returnable',
    );
  }
}
