import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart' as catalog;
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/browse_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart' as catalog_params;
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_order_line.dart';

/// Searches the real product catalog (`order` feature's `ProductRepository`,
/// via `BrowseProducts`) rather than inventing a second product concept —
/// one source of truth for products across the app.
Future<VisitOrderLine?> showOrderCaptureSheet({required BuildContext context, required String stopId}) {
  return showModalBottomSheet<VisitOrderLine>(
    context: context,
    backgroundColor: Vibe.bgSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => _OrderCaptureSheet(stopId: stopId),
  );
}

class _OrderCaptureSheet extends StatefulWidget {
  const _OrderCaptureSheet({required this.stopId});
  final String stopId;

  @override
  State<_OrderCaptureSheet> createState() => _OrderCaptureSheetState();
}

class _OrderCaptureSheetState extends State<_OrderCaptureSheet> {
  final _searchController = TextEditingController();
  List<catalog.Product> _results = const [];
  catalog.Product? _selected;
  double _quantity = 1;
  bool _searching = false;

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    final result = await sl<BrowseProducts>()(
      catalog_params.BrowseProductsParams(page: 0, pageSize: 20, query: query),
    );
    if (!mounted) return;
    result.when(
      success: (paged) => setState(() {
        _results = paged.items;
        _searching = false;
      }),
      failure: (_) => setState(() {
        _results = const [];
        _searching = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Capture Order', style: TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Search products…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Vibe.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              if (_searching) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Vibe.violet)),
              if (!_searching && _results.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final p = _results[i];
                      final selected = _selected?.id == p.id;
                      return ListTile(
                        selected: selected,
                        selectedTileColor: Vibe.primaryLight.withValues(alpha: 0.4),
                        title: Text(p.name, style: const TextStyle(color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: Text('${p.code} · \$${p.effectivePrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
                        onTap: () => setState(() => _selected = p),
                      );
                    },
                  ),
                ),
              if (_selected != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Quantity', style: const TextStyle(color: Vibe.muted, fontSize: 12.5)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity = (_quantity - 1).clamp(1, 99999)),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text(_quantity.toStringAsFixed(0), style: const TextStyle(color: Vibe.text, fontWeight: FontWeight.w800)),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.pop(
                            context,
                            VisitOrderLine(
                              id: '${DateTime.now().microsecondsSinceEpoch}',
                              stopId: widget.stopId,
                              productId: _selected!.id,
                              productName: _selected!.name,
                              quantity: _quantity,
                              unit: _selected!.unit,
                              unitPrice: _selected!.effectivePrice,
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Vibe.violet,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add to Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
