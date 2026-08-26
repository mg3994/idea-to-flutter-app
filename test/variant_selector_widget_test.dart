import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';
import 'package:blog_store/features/catalog/presentation/product_detail_screen.dart';

void main() {
  testWidgets('Renders sibling variant choices and switches active product state', (WidgetTester tester) async {
    final v1 = ProductEntity(
      id: 'v1',
      blogId: 'b1',
      title: 'Red Edition 64GB',
      price: 699.0,
      labels: [],
      rawSchema: {'@base': 'b1/m1'},
      resolvedSchema: {},
      publishedAt: '2025-01-01T00:00:00Z',
    );

    final v2 = ProductEntity(
      id: 'v2',
      blogId: 'b1',
      title: 'Blue Edition 128GB',
      price: 799.0,
      labels: [],
      rawSchema: {'@base': 'b1/m1'},
      resolvedSchema: {},
      publishedAt: '2025-01-01T00:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          product: v1,
          siblingVariants: [v1, v2],
          onAddToCart: (_) {},
          onToggleWishlist: (_) {},
        ),
      ),
    );

    expect(find.text('Red Edition 64GB'), findsNWidgets(2)); // Title & Chip
    expect(find.text('Blue Edition 128GB'), findsOneWidget); // ChoiceChip

    await tester.tap(find.text('Blue Edition 128GB'));
    await tester.pumpAndSettle();

    expect(find.text('Blue Edition 128GB'), findsNWidgets(2)); // Active Product Title & Chip
  });
}
