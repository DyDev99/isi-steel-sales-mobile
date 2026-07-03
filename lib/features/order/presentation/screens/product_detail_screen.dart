import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/price_tier.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/mto_pricing_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_detail_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/promotion_badge.dart';

/// Product detail — pushed from [CatalogScreen] (tap or barcode scan) or
/// from a variant chip within this same screen (re-`load`s in place).
/// [leadId], when set, tags any cart addition to that lead's opportunity.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId, this.leadId});
  final String productId;
  final String? leadId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductDetailCubit>()..load(productId),
      child: _ProductDetailView(leadId: leadId),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView({this.leadId});
  final String? leadId;

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  double _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: SafeArea(
        child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
          builder: (context, state) => switch (state) {
            ProductDetailLoaded() => _Loaded(state: state, quantity: _quantity, onQuantityChanged: (q) => setState(() => _quantity = q), leadId: widget.leadId),
            ProductDetailError(:final message) => Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
            _ => const Center(child: CircularProgressIndicator(color: Vibe.violet)),
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.quantity, required this.onQuantityChanged, this.leadId});
  final ProductDetailLoaded state;
  final double quantity;
  final ValueChanged<double> onQuantityChanged;
  final String? leadId;

  Future<void> _requestMtoQuote(BuildContext context) async {
    final result = await sl<MtoPricingService>().requestQuote(state.product);
    if (!context.mounted) return;
    result.when(
      success: (quote) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Vibe.bgSoft,
          title: const Text('MTO Quote', style: TextStyle(color: Vibe.text)),
          content: Text(
            quote.available
                ? '${quote.message}\n\nEstimated price: \$${quote.price?.toStringAsFixed(2)}'
                : quote.message,
            style: const TextStyle(color: Vibe.muted),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      ),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = state.product;
    final cubit = context.read<ProductDetailCubit>();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Vibe.text),
                  ),
                  Expanded(
                    child: Text(product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: cubit.toggleFavorite,
                    icon: Icon(
                      state.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: state.isFavorite ? Vibe.danger : Vibe.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Vibe.bgSoft,
                      alignment: Alignment.center,
                      child: const Icon(Icons.inventory_2_outlined, color: Vibe.muted, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Chip(label: product.code, color: Vibe.muted),
                _Chip(label: product.status.label, color: product.status.name == 'active' ? Vibe.success : Vibe.amber),
                if (product.hasPromotion) PromotionBadge(label: product.pricing.promotionLabel ?? 'Sale'),
                if (product.isMto) const _Chip(label: 'Made to Order', color: Vibe.violet),
              ]),

              if (state.variants.length > 1) ...[
                const SizedBox(height: 16),
                const _SectionTitle('Other Sizes'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final variant in state.variants)
                      InkWell(
                        onTap: () => cubit.load(variant.id),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: variant.id == product.id ? Vibe.violet.withValues(alpha: 0.18) : Vibe.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: variant.id == product.id ? Vibe.violet : Vibe.stroke),
                          ),
                          child: Text(variant.size,
                              style: TextStyle(
                                  color: variant.id == product.id ? Vibe.violet : Vibe.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              _Section(
                title: 'Pricing',
                child: Column(
                  children: [
                    for (final tier in PriceTier.values)
                      _KeyValue(tier.label, '\$${product.pricing.priceFor(tier).toStringAsFixed(2)}'),
                    if (product.hasPromotion)
                      _KeyValue('Promotion price', '\$${product.pricing.promotionPrice!.toStringAsFixed(2)}'),
                    if (product.isMto) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _requestMtoQuote(context),
                          child: const Text('Request MTO Quote'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              _Section(
                title: 'Specifications',
                child: Column(
                  children: [
                    _KeyValue('Material code', product.materialCode),
                    _KeyValue('SKU', product.sku),
                    _KeyValue('Barcode', product.barcode),
                    _KeyValue('Brand', product.brand),
                    _KeyValue('Grade', product.grade),
                    _KeyValue('Material', product.material),
                    _KeyValue('Size', product.size),
                    if (product.diameter > 0) _KeyValue('Diameter', '${product.diameter} mm'),
                    if (product.thickness > 0) _KeyValue('Thickness', '${product.thickness} mm'),
                    if (product.length > 0) _KeyValue('Length', '${product.length} m'),
                    if (product.width > 0) _KeyValue('Width', '${product.width} mm'),
                    if (product.height > 0) _KeyValue('Height', '${product.height} mm'),
                    _KeyValue('Weight', '${product.weight.toStringAsFixed(2)} kg'),
                    _KeyValue('Unit', product.unit),
                    _KeyValue('Description', product.description),
                  ],
                ),
              ),

              _Section(
                title: 'Stock',
                child: Column(
                  children: [
                    _KeyValue('Available', '${product.availableQuantity.toStringAsFixed(0)} ${product.unit}'),
                    _KeyValue('On hand', '${product.stockQuantity.toStringAsFixed(0)} ${product.unit}'),
                    _KeyValue('Reserved', '${product.reservedQuantity.toStringAsFixed(0)} ${product.unit}'),
                    _KeyValue('Min / Max stock', '${product.minStock.toStringAsFixed(0)} / ${product.maxStock.toStringAsFixed(0)}'),
                    if (product.isBelowMinStock)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Below minimum stock level', style: TextStyle(color: Vibe.danger, fontSize: 11.5)),
                      ),
                  ],
                ),
              ),

              if (state.warehouseStock.isNotEmpty)
                _Section(
                  title: 'Warehouse Stock',
                  child: Column(
                    children: [
                      for (final row in state.warehouseStock)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${row.warehouseCode} · ${row.territory}',
                                    style: const TextStyle(color: Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
                              ),
                              Text('${row.availableQuantity.toStringAsFixed(0)} ${row.unit}',
                                  style: const TextStyle(color: Vibe.muted, fontSize: 12.5)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _AddToCartBar(product: product, quantity: quantity, onQuantityChanged: onQuantityChanged, leadId: leadId),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({required this.product, required this.quantity, required this.onQuantityChanged, this.leadId});
  final Product product;
  final double quantity;
  final ValueChanged<double> onQuantityChanged;
  final String? leadId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(color: Vibe.bg, border: Border(top: BorderSide(color: Vibe.stroke))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _QtyButton(icon: Icons.remove_rounded, onTap: () => onQuantityChanged((quantity - 1).clamp(1, 999999))),
            SizedBox(
              width: 44,
              child: Text(quantity.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            _QtyButton(icon: Icons.add_rounded, onTap: () => onQuantityChanged(quantity + 1)),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: product.isAvailable
                    ? () {
                        context.read<CartCubit>().addProduct(product, quantity: quantity, leadId: leadId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} added to cart')),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Vibe.violet,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(product.isAvailable
                    ? 'Add to Cart · \$${(product.effectivePrice * quantity).toStringAsFixed(2)}'
                    : 'Out of Stock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Vibe.surface,
          border: Border.all(color: Vibe.stroke),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: Vibe.text),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Vibe.text, fontSize: 14.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: Vibe.text, fontSize: 14.5, fontWeight: FontWeight.w800)),
      );
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Vibe.muted, fontSize: 12.5))),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(color: Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
