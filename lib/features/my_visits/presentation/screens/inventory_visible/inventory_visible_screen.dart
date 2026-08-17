import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Mock Model for Stock Visual Audit Item
class DepotStockItem {
  DepotStockItem({
    required this.id,
    required this.nameKh,
    required this.nameEn,
    required this.unit,
    this.visualCount = 0,
    this.status = StockStatus.inStock,
  });

  final String id;
  final String nameKh;
  final String nameEn;
  final String unit;
  int visualCount;
  StockStatus status;
}

enum StockStatus { inStock, lowStock, outOfStock }

class InventoryVisibilityScreen extends StatefulWidget {
  const InventoryVisibilityScreen({
    super.key,
    required this.depotName,
    required this.onSubmit,
  });

  /// `RouteSettings.name` for this screen — the resume-dispatcher key that
  /// lets "Continue Working" rebuild it after a checked-in stop with no
  /// further progress (see `resume_workflow_dispatcher.dart`).
  static const String routeName = 'my-visits-inventory-visibility';

  final String depotName;
  final VoidCallback onSubmit;

  @override
  State<InventoryVisibilityScreen> createState() => _InventoryVisibilityScreenState();
}

class _InventoryVisibilityScreenState extends State<InventoryVisibilityScreen> {
  final String _searchQuery = '';
  
  // Mock Depot Inventory Data
  final List<DepotStockItem> _items = [
    DepotStockItem(id: '1', nameKh: 'ដែកទីបមូល (INP)', nameEn: 'Pipe Tube 2"', unit: 'Pcs', visualCount: 150, status: StockStatus.inStock),
    DepotStockItem(id: '2', nameKh: 'ស័ង្កសីរលក C-Channel', nameEn: 'Zincalume Sheet 0.4mm', unit: 'Sheets', visualCount: 12, status: StockStatus.lowStock),
    DepotStockItem(id: '3', nameKh: 'ដែកអក្សរ H (H-Beam)', nameEn: 'H-Beam 100x100', unit: 'Pcs', visualCount: 0, status: StockStatus.outOfStock),
    DepotStockItem(id: '4', nameKh: 'ដែកប្រអប់ square', nameEn: 'Hollow Pipe 50x50', unit: 'Pcs', visualCount: 85, status: StockStatus.inStock),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Visibility (Required)',
              style: TextStyle(fontSize: context.rsp(16), fontWeight: FontWeight.w800),
            ),
            Text(
              widget.depotName,
              style: TextStyle(fontSize: context.rsp(11.5), color: colors.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instruction banner for rep
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: context.rw(16), vertical: context.rh(10)),
              color: scheme.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(Icons.visibility_rounded, color: scheme.primary, size: context.rr(20)),
                  SizedBox(width: context.rw(10)),
                  Expanded(
                    child: Text(
                      'Visually inspect and log available stock counts in depot.',
                      style: TextStyle(fontSize: context.rsp(12), color: colors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Product List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(context.rw(16)),
                itemCount: _items.length,
                separatorBuilder: (_, __) => SizedBox(height: context.rh(12)),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _StockItemAuditCard(
                    item: item,
                    onCountChanged: (newCount) {
                      setState(() => item.visualCount = newCount);
                    },
                    onStatusChanged: (status) {
                      setState(() => item.status = status);
                    },
                  );
                },
              ),
            ),

            // Bottom Sticky Submit Button
            Container(
              padding: EdgeInsets.all(context.rw(16)),
              decoration: BoxDecoration(
                color: colors.card,
                border: Border(top: BorderSide(color: colors.border)),
                boxShadow: colors.cardShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onSubmit();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  minimumSize: Size(double.infinity, context.rh(48)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.rr(12))),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  'Submit Stock Check',
                  style: TextStyle(fontSize: context.rsp(15), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockItemAuditCard extends StatelessWidget {
  const _StockItemAuditCard({
    required this.item,
    required this.onCountChanged,
    required this.onStatusChanged,
  });

  final DepotStockItem item;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<StockStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.all(context.rw(14)),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(14)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Item Name
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.nameKh} (${item.nameEn})',
                      style: TextStyle(
                        fontSize: context.rsp(14),
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Unit: ${item.unit}',
                      style: TextStyle(fontSize: context.rsp(11), color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(12)),

          // Stepper & Preset Count Buttons (Designed for fast field tap)
          Row(
            children: [
              // Count Stepper
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(context.rr(10)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded),
                      onPressed: item.visualCount > 0 ? () => onCountChanged(item.visualCount - 1) : null,
                    ),
                    Container(
                      constraints: BoxConstraints(minWidth: context.rw(40)),
                      alignment: Alignment.center,
                      child: Text(
                        '${item.visualCount}',
                        style: TextStyle(
                          fontSize: context.rsp(16),
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => onCountChanged(item.visualCount + 1),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.rw(10)),

              // Quick presets (+5, +10, +50) for fast rep entry
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [5, 10, 50].map((step) {
                      return Padding(
                        padding: EdgeInsets.only(right: context.rw(6)),
                        child: InkWell(
                          onTap: () => onCountChanged(item.visualCount + step),
                          borderRadius: BorderRadius.circular(context.rr(8)),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: context.rw(10), vertical: context.rh(8)),
                            decoration: BoxDecoration(
                              color: colors.border.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(context.rr(8)),
                            ),
                            child: Text(
                              '+$step',
                              style: TextStyle(fontSize: context.rsp(11.5), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}