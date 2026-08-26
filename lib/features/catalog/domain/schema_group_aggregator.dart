import '../domain/product_entity.dart';

class ProductGroup {
  final String masterId;
  final ProductEntity? masterProduct;
  final List<ProductEntity> variants;

  ProductGroup({
    required this.masterId,
    this.masterProduct,
    required this.variants,
  });
}

class SchemaGroupAggregator {
  /// Groups a list of products into ProductGroups based on shared @base master post anchors
  static List<ProductGroup> aggregate(List<ProductEntity> products) {
    final Map<String, List<ProductEntity>> groupsMap = {};
    final Map<String, ProductEntity> masterProductsMap = {};

    for (final product in products) {
      final baseRaw = product.rawSchema['@base'] as String?;
      if (baseRaw != null && baseRaw.isNotEmpty) {
        final masterKey = baseRaw.trim();
        groupsMap.putIfAbsent(masterKey, () => []).add(product);
      } else {
        final masterKey = '${product.blogId}/${product.id}';
        masterProductsMap[masterKey] = product;
        groupsMap.putIfAbsent(masterKey, () => []);
      }
    }

    final List<ProductGroup> resultGroups = [];

    groupsMap.forEach((masterId, variantList) {
      resultGroups.add(ProductGroup(
        masterId: masterId,
        masterProduct: masterProductsMap[masterId],
        variants: variantList,
      ));
    });

    return resultGroups;
  }
}
