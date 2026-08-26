import 'package:flutter/material.dart';
import '../domain/product_entity.dart';
import '../domain/product_comparison_utility.dart';

class ProductComparisonScreen extends StatelessWidget {
  final List<ProductEntity> products;

  const ProductComparisonScreen({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final matrix = ProductComparisonUtility.buildMatrix(products);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Specification Comparison'),
      ),
      body: products.isEmpty
          ? const Center(child: Text('No products selected for comparison.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...products.map(
                      (p) => DataColumn(
                        label: SizedBox(
                          width: 140,
                          child: Text(
                            p.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                  rows: matrix.map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(row.propertyKey, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ...products.map(
                          (p) => DataCell(
                            Text(row.productValues[p.id] ?? '-'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
