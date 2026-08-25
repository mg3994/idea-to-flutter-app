import 'package:flutter/material.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import '../data/app_database.dart';

class WishlistScreen extends StatelessWidget {
  final Signal<List<WishlistItem>> wishlistItemsSignal;
  final AppDatabase database;
  final VoidCallback onWishlistUpdated;
  final Function(String postId, String title, double price, String? imageUrl, String schemaJson) onMoveToCart;

  const WishlistScreen({
    super.key,
    required this.wishlistItemsSignal,
    required this.database,
    required this.onWishlistUpdated,
    required this.onMoveToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
      ),
      body: BlocSignalBuilder<List<WishlistItem>>(
        signal: wishlistItemsSignal,
        builder: (context, items) {
          if (items.isEmpty) {
            return const Center(child: Text('Your wishlist is empty.'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: item.imageUrl != null
                      ? Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.favorite, color: Colors.red),
                  title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('\$${item.price.toStringAsFixed(2)} ${item.currency}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_checkout, color: Colors.deepPurple),
                        tooltip: 'Move to Cart',
                        onPressed: () async {
                          await (database.delete(database.wishlistItems)
                                ..where((tbl) => tbl.id.equals(item.id)))
                              .go();
                          onMoveToCart(item.postId, item.title, item.price, item.imageUrl, item.schemaJson);
                          onWishlistUpdated();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${item.title} moved to cart!')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () async {
                          await (database.delete(database.wishlistItems)
                                ..where((tbl) => tbl.id.equals(item.id)))
                              .go();
                          onWishlistUpdated();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
