import 'dart:convert';
import 'package:drift/drift.dart';
import '../../checkout/data/checkout_client.dart';
import 'app_database.dart';

class OfflineOrderSyncManager {
  final AppDatabase database;
  final CheckoutClient checkoutClient;

  OfflineOrderSyncManager({
    required this.database,
    required this.checkoutClient,
  });

  /// Queues an order for sync when offline
  Future<void> queueOrder(CheckoutPayload payload) async {
    await database.into(database.queuedOrders).insert(
          QueuedOrdersCompanion.insert(
            queueId: 'q_${DateTime.now().millisecondsSinceEpoch}',
            payloadJson: jsonEncode(payload.toJson()),
          ),
        );
  }

  /// Syncs pending queued orders with Cloudflare Worker Hono API
  Future<int> syncQueuedOrders() async {
    final pending = await (database.select(database.queuedOrders)
          ..where((tbl) => tbl.status.equals('PENDING')))
        .get();

    int syncedCount = 0;

    for (final queued in pending) {
      try {
        final Map<String, dynamic> rawMap = jsonDecode(queued.payloadJson) as Map<String, dynamic>;
        final items = (rawMap['items'] as List)
            .map((i) => OrderItem(
                  id: i['id'],
                  title: i['title'],
                  price: (i['price'] as num).toDouble(),
                  quantity: i['quantity'],
                ))
            .toList();

        final payload = CheckoutPayload(
          userId: rawMap['userId'],
          items: items,
          totalAmount: (rawMap['totalAmount'] as num).toDouble(),
          paymentMethod: PaymentMethod.values.firstWhere(
            (e) => e.name == rawMap['paymentMethod'],
            orElse: () => PaymentMethod.cod,
          ),
          shippingAddress: Map<String, String>.from(rawMap['shippingAddress'] ?? {}),
        );

        final response = await checkoutClient.processOrder(payload);

        if (response.success) {
          // Mark as SYNCED
          await (database.update(database.queuedOrders)
                ..where((tbl) => tbl.queueId.equals(queued.queueId)))
              .write(const QueuedOrdersCompanion(status: Value('SYNCED')));

          // Save to local OrderRecords
          await database.into(database.orderRecords).insertOnConflictUpdate(
                OrderRecordsCompanion.insert(
                  orderId: response.orderId ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
                  userId: payload.userId,
                  totalAmount: payload.totalAmount,
                  paymentMethod: payload.paymentMethod.name,
                  itemsJson: jsonEncode(payload.items.map((i) => i.toJson()).toList()),
                  shippingAddressJson: jsonEncode(payload.shippingAddress),
                ),
              );

          syncedCount++;
        }
      } catch (_) {
        // Leave in PENDING state for future retry
      }
    }

    return syncedCount;
  }
}
