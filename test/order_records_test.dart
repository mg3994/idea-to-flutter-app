import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:blog_store/features/cart_wishlist/data/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Inserts and retrieves OrderRecords from Drift DB', () async {
    await database.into(database.orderRecords).insert(
          OrderRecordsCompanion.insert(
            orderId: 'ORD-999',
            userId: 'user_test',
            totalAmount: 149.99,
            paymentMethod: 'upi',
            itemsJson: '[]',
            shippingAddressJson: '{"city": "Paris"}',
          ),
        );

    final orders = await database.select(database.orderRecords).get();

    expect(orders.length, 1);
    expect(orders.first.orderId, 'ORD-999');
    expect(orders.first.totalAmount, 149.99);
    expect(orders.first.paymentMethod, 'upi');
  });
}
