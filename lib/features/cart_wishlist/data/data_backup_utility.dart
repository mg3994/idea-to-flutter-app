import 'dart:convert';
import 'package:drift/drift.dart';
import 'app_database.dart';

class DataBackupUtility {
  final AppDatabase database;

  DataBackupUtility({required this.database});

  /// Exports local Cart and Wishlist items into a backup JSON string
  Future<String> exportBackupJson() async {
    final cartItems = await database.select(database.cartItems).get();
    final wishlistItems = await database.select(database.wishlistItems).get();

    final exportMap = {
      'exportedAt': DateTime.now().toIso8601String(),
      'cart': cartItems
          .map((c) => {
                'id': c.id,
                'postId': c.postId,
                'blogId': c.blogId,
                'title': c.title,
                'price': c.price,
                'currency': c.currency,
                'imageUrl': c.imageUrl,
                'quantity': c.quantity,
                'schemaJson': c.schemaJson,
              })
          .toList(),
      'wishlist': wishlistItems
          .map((w) => {
                'id': w.id,
                'postId': w.postId,
                'blogId': w.blogId,
                'title': w.title,
                'price': w.price,
                'currency': w.currency,
                'imageUrl': w.imageUrl,
                'schemaJson': w.schemaJson,
              })
          .toList(),
    };

    return jsonEncode(exportMap);
  }

  /// Restores Cart and Wishlist items from a backup JSON string
  Future<void> importBackupJson(String backupJson) async {
    final Map<String, dynamic> data = jsonDecode(backupJson) as Map<String, dynamic>;

    if (data['cart'] != null && data['cart'] is List) {
      for (final item in data['cart']) {
        await database.into(database.cartItems).insertOnConflictUpdate(
              CartItemsCompanion.insert(
                id: item['id'],
                postId: item['postId'],
                blogId: item['blogId'],
                title: item['title'],
                price: (item['price'] as num).toDouble(),
                currency: Value(item['currency'] ?? 'USD'),
                imageUrl: Value(item['imageUrl']),
                quantity: Value(item['quantity'] ?? 1),
                schemaJson: item['schemaJson'] ?? '{}',
              ),
            );
      }
    }

    if (data['wishlist'] != null && data['wishlist'] is List) {
      for (final item in data['wishlist']) {
        await database.into(database.wishlistItems).insertOnConflictUpdate(
              WishlistItemsCompanion.insert(
                id: item['id'],
                postId: item['postId'],
                blogId: item['blogId'],
                title: item['title'],
                price: (item['price'] as num).toDouble(),
                currency: Value(item['currency'] ?? 'USD'),
                imageUrl: Value(item['imageUrl']),
                schemaJson: item['schemaJson'] ?? '{}',
              ),
            );
      }
    }
  }
}
