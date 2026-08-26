enum ItemCondition {
  newCondition,
  refurbishedCondition,
  usedCondition,
  damagedCondition,
  unknown,
}

class SchemaConditionChecker {
  /// Parses Schema.org itemCondition from resolved schema e.g. "https://schema.org/NewCondition" or "NewCondition"
  static ItemCondition checkCondition(Map<String, dynamic> schema) {
    dynamic conditionNode = schema['itemCondition'];

    if (conditionNode == null && schema['offers'] != null) {
      final offers = schema['offers'];
      if (offers is Map) {
        conditionNode = offers['itemCondition'];
      } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
        conditionNode = offers.first['itemCondition'];
      }
    }

    if (conditionNode == null) return ItemCondition.newCondition;

    final val = conditionNode.toString().toLowerCase();

    if (val.contains('newcondition') || val.contains('brandnew')) return ItemCondition.newCondition;
    if (val.contains('refurbished') || val.contains('renewed')) return ItemCondition.refurbishedCondition;
    if (val.contains('used') || val.contains('preowned')) return ItemCondition.usedCondition;
    if (val.contains('damaged')) return ItemCondition.damagedCondition;

    return ItemCondition.unknown;
  }

  static String formatConditionName(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.newCondition:
        return 'Brand New';
      case ItemCondition.refurbishedCondition:
        return 'Refurbished';
      case ItemCondition.usedCondition:
        return 'Pre-Owned / Used';
      case ItemCondition.damagedCondition:
        return 'Damaged';
      case ItemCondition.unknown:
      default:
        return 'Standard Condition';
    }
  }
}
