import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/product_card.dart';

/// Product Grid — 2-column grid of [ProductCard]s.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onIncrement,
    required this.onDecrement,
  });

  final List<ProductViewModel> products;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          viewModel: product,
          onIncrement: () => onIncrement(product.id),
          onDecrement: () => onDecrement(product.id),
        );
      },
    );
  }
}
