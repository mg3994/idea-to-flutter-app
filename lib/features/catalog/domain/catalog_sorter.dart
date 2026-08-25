import '../domain/product_entity.dart';

enum SortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  newest,
}

class CatalogSorter {
  static List<ProductEntity> sort(List<ProductEntity> products, SortOption option) {
    final list = List<ProductEntity>.from(products);
    switch (option) {
      case SortOption.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.newest:
        list.sort((a, b) {
          final dtA = DateTime.tryParse(a.publishedAt) ?? DateTime(1970);
          final dtB = DateTime.tryParse(b.publishedAt) ?? DateTime(1970);
          return dtB.compareTo(dtA);
        });
        break;
      case SortOption.featured:
      default:
        break;
    }
    return list;
  }
}
