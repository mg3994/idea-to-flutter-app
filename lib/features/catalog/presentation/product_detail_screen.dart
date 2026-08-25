import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/product_entity.dart';
import '../../../shared/i18n/schema_i18n_resolver.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductEntity product;
  final Function(ProductEntity) onAddToCart;
  final Function(ProductEntity) onToggleWishlist;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onToggleWishlist,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _showRawSchema = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final formattedDate = SchemaI18nResolver.formatLocalTimestamp(product.publishedAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => widget.onToggleWishlist(product),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: product.imageUrl != null
                  ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '\$${product.price.toStringAsFixed(2)} ${product.currency}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (product.brand != null)
                    Chip(
                      avatar: const Icon(Icons.branding_watermark, size: 16),
                      label: Text('Brand: ${product.brand}'),
                    ),
                  if (product.sku != null)
                    Text('SKU: ${product.sku}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('Published: $formattedDate', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(product.description ?? 'No description available.'),
                  const SizedBox(height: 20),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Resolved Schema Specs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        icon: Icon(_showRawSchema ? Icons.code_off : Icons.code),
                        label: Text(_showRawSchema ? 'Hide Raw JSON' : 'View Raw JSON'),
                        onPressed: () => setState(() => _showRawSchema = !_showRawSchema),
                      ),
                    ],
                  ),
                  if (_showRawSchema)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        const JsonEncoder.withIndent('  ').convert(product.resolvedSchema),
                        style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12),
                      ),
                    )
                  else
                    ...product.resolvedSchema.entries.map((entry) {
                      if (entry.key.startsWith('@')) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                              ),
                            ),
                            Expanded(
                              child: Text(entry.value.toString()),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.shopping_cart),
          label: const Text('Add to Cart', style: TextStyle(fontSize: 16)),
          onPressed: () {
            widget.onAddToCart(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${product.title} added to cart!')),
            );
          },
        ),
      ),
    );
  }
}
