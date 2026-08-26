import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/product_entity.dart';
import '../../../shared/i18n/schema_i18n_resolver.dart';
import '../../../shared/i18n/currency_converter.dart';
import '../domain/schema_share_utility.dart';
import '../../../core/utils/schema_audit_utility.dart';
import '../../../core/utils/schema_export_manager.dart';

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
            icon: const Icon(Icons.share),
            tooltip: 'Share Product',
            onPressed: () {
              final shareText = SchemaShareUtility.generateShareText(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied link: $shareText'),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
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
                  const Divider(),
                  Builder(
                    builder: (context) {
                      final auditReport = SchemaAuditUtility.audit(product.resolvedSchema);
                      return Card(
                        color: auditReport.healthScorePercentage >= 80
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        auditReport.healthScorePercentage >= 80 ? Icons.verified : Icons.warning_amber,
                                        color: auditReport.healthScorePercentage >= 80 ? Colors.green : Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Schema Health Score: ${auditReport.healthScorePercentage}%',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Chip(
                                    label: Text(
                                      auditReport.isValidProduct ? 'Valid Schema' : 'Incomplete',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: auditReport.isValidProduct ? Colors.green.shade100 : Colors.red.shade100,
                                  ),
                                ],
                              ),
                              if (auditReport.missingFields.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Missing Required Fields: ${auditReport.missingFields.join(", ")}',
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ],
                              if (auditReport.warnings.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Warnings: ${auditReport.warnings.join(", ")}',
                                  style: const TextStyle(color: Colors.orange, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
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
                        CurrencyConverter.format(
                          price: product.price,
                          fromCurrency: product.currency,
                          targetCurrency: product.currency,
                        ),
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
                  if (product.ratingValue != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${product.ratingValue!.toStringAsFixed(1)} / 5.0',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (product.reviewCount != null) ...[
                          const SizedBox(width: 6),
                          Text('(${product.reviewCount} reviews)', style: const TextStyle(color: Colors.grey)),
                        ],
                      ],
                    ),
                  ],
                  if (product.sku != null)
                    Text('SKU: ${product.sku}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('Published: $formattedDate', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(product.description ?? 'No description available.'),
                  if (product.reviews.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...product.reviews.map((rev) {
                      final author = rev['author'] is Map ? rev['author']['name'] : rev['author']?.toString() ?? 'Anonymous';
                      final body = rev['reviewBody']?.toString() ?? rev['description']?.toString() ?? '';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(body, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Resolved Schema Specs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copy Microdata HTML',
                            onPressed: () {
                              final snippet = SchemaExportManager.generateHtmlMicrodataSnippet(product.resolvedSchema);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied HTML Microdata snippet for "${product.title}"')),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: Icon(_showRawSchema ? Icons.code_off : Icons.code),
                            label: Text(_showRawSchema ? 'Hide Raw JSON' : 'View Raw JSON'),
                            onPressed: () => setState(() => _showRawSchema = !_showRawSchema),
                          ),
                        ],
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
