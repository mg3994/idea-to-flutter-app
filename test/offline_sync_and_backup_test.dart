import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:blog_store/features/cart_wishlist/data/app_database.dart';
import 'package:blog_store/features/cart_wishlist/data/offline_order_sync_manager.dart';
import 'package:blog_store/features/cart_wishlist/data/data_backup_utility.dart';
import 'package:blog_store/features/checkout/data/checkout_client.dart';

void main() {
  late AppDatabase database;
  late OfflineOrderSyncManager syncManager;
  late DataBackupUtility backupUtility;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    syncManager = OfflineOrderSyncManager(
      database: database,
      checkoutClient: CheckoutClient(dio: Dio()),
    );
    backupUtility = DataBackupUtility(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Queues order and syncs queued orders', () async {
    final payload = CheckoutPayload(
      userId: 'user_queue_test',
      items: [OrderItem(id: 'p_1', title: 'Tablet', price: 299.99, quantity: 1)],
      totalAmount: 299.99,
      paymentMethod: PaymentMethod.cod,
      shippingAddress: {'city': 'London', 'country': 'UK'},
    );

    await syncManager.queueOrder(payload);

    final queued = await database.select(database.queuedOrders).get();
    expect(queued.length, 1);
    expect(queued.first.status, 'PENDING');
  });

  test('Exports and imports Cart and Wishlist backups', () async {
    await database.into(database.cartItems).insert(
          CartItemsCompanion.insert(
            id: 'c1',
            postId: 'p1',
            blogId: 'b1',
            title: 'Headphones',
            price: 79.99,
            schemaJson: '{}',
          ),
        );

    final jsonBackup = await backupUtility.exportBackupJson();
    expect(jsonBackup, contains('Headphones'));

    await database.delete(database.cartItems).go();
    expect((await database.select(database.cartItems).get()).isEmpty, isTrue);

    await backupUtility.importBackupJson(jsonBackup);
    final restoredCart = await database.select(database.cartItems).get();
    expect(restoredCart.length, 1);
    expect(restoredCart.first.title, 'Headphones');
  });
}
