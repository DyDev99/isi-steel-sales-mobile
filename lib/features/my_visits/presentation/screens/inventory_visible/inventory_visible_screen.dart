import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/animations/app_animations.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Mock model for a depot stock visual audit item.
class DepotStockItem {
  DepotStockItem({
    required this.id,
    required this.nameKh,
    required this.nameEn,
    required this.unit,
    this.status,
  });

  final String id;
  final String nameKh;
  final String nameEn;
  final String unit;

  /// The level the rep observed, or null until they have judged this item.
  ///
  /// Deliberately **not** defaulted. This screen is an audit: if every row
  /// arrives pre-answered, a rep can submit a full stock check without having
  /// looked at anything, and the record is indistinguishable from one that was
  /// actually walked. Null forces a deliberate choice per item, which is the
  /// only thing that makes the resulting data worth collecting.
  StockStatus? status;
}

/// How much of an item the depot is holding, judged by eye.
///
/// A three-way judgement rather than a counted quantity: a rep standing in a
/// warehouse can tell a full rack from a nearly-empty one in a second, but
/// counting 150 lengths of pipe by hand is slow and the number is wrong by the
/// time it is typed. Three levels are what a visual sweep can actually support
/// — and they are what the reorder decision downstream needs.
enum StockStatus { high, medium, low }

extension StockStatusView on StockStatus {
  String get labelKey => switch (this) {
        StockStatus.high => 'my_visits.inventory.level_high',
        StockStatus.medium => 'my_visits.inventory.level_medium',
        StockStatus.low => 'my_visits.inventory.level_low',
      };

  IconData get icon => switch (this) {
        // A filled bar that empties as the level drops — readable at a glance
        // without relying on colour alone, which matters both for colour-blind
        // reps and in direct sunlight.
        StockStatus.high => Icons.signal_cellular_alt_rounded,
        StockStatus.medium => Icons.signal_cellular_alt_2_bar_rounded,
        StockStatus.low => Icons.signal_cellular_alt_1_bar_rounded,
      };

  Color color(BuildContext context) => switch (this) {
        StockStatus.high => context.appColors.success,
        StockStatus.medium => context.appColors.warning,
        StockStatus.low => Theme.of(context).colorScheme.error,
      };
}

class InventoryVisibilityScreen extends StatefulWidget {
  const InventoryVisibilityScreen({
    super.key,
    required this.depotName,
    required this.onSubmit,
    this.initialStatuses = const {},
    this.onProgressChanged,
  });

  /// `RouteSettings.name` for this screen — the resume-dispatcher key that
  /// lets "Continue Working" rebuild it after a checked-in stop with no
  /// further progress (see `resume_workflow_dispatcher.dart`).
  static const String routeName = 'my-visits-inventory-visibility';

  final String depotName;
  final VoidCallback onSubmit;

  /// Judgements already recorded for this depot, keyed by item id.
  ///
  /// A half-finished audit is the normal case, not an edge case: a rep is
  /// interrupted mid-aisle by a customer, backs out to take a call, or the app
  /// is killed in the background. Re-opening to a blank sheet means walking the
  /// racks twice, so "Continue Working" restores exactly what was judged.
  final Map<String, StockStatus> initialStatuses;

  /// Fires on every judgement with the complete current picture, so the caller
  /// can persist it. Reported as a whole map rather than a delta because the
  /// receiver stores a snapshot — sending deltas would make the caller
  /// responsible for reassembling state it does not own.
  final ValueChanged<Map<String, StockStatus>>? onProgressChanged;

  @override
  State<InventoryVisibilityScreen> createState() =>
      _InventoryVisibilityScreenState();
}

class _InventoryVisibilityScreenState extends State<InventoryVisibilityScreen> {
  // Mock depot inventory data.
  final List<DepotStockItem> _items = [
    DepotStockItem(
        id: '1',
        nameKh: 'ដែកទីបមូល (INP)',
        nameEn: 'Pipe Tube 2"',
        unit: 'Pcs'),
    DepotStockItem(
        id: '2',
        nameKh: 'ស័ង្កសីរលក C-Channel',
        nameEn: 'Zincalume Sheet 0.4mm',
        unit: 'Sheets'),
    DepotStockItem(
        id: '3',
        nameKh: 'ដែកអក្សរ H (H-Beam)',
        nameEn: 'H-Beam 100x100',
        unit: 'Pcs'),
    DepotStockItem(
        id: '4',
        nameKh: 'ដែកប្រអប់ square',
        nameEn: 'Hollow Pipe 50x50',
        unit: 'Pcs'),
  ];

  @override
  void initState() {
    super.initState();
    // Restore a partially-completed audit.
    for (final item in _items) {
      item.status = widget.initialStatuses[item.id];
    }
  }

  int get _assessed => _items.where((i) => i.status != null).length;
  bool get _complete => _assessed == _items.length;

  Map<String, StockStatus> get _progress => {
        for (final i in _items)
          if (i.status != null) i.id: i.status!,
      };

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
              '${'my_visits.inventory.title'.tr} (${'my_visits.inventory.required'.tr})',
              style: TextStyle(
                  fontSize: context.rsp(16), fontWeight: FontWeight.w800),
            ),
            Text(
              widget.depotName,
              style: TextStyle(
                  fontSize: context.rsp(11.5), color: colors.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instruction banner for the rep.
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: context.rw(16), vertical: context.rh(10)),
              color: scheme.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(Icons.visibility_rounded,
                      color: scheme.primary, size: context.rr(20)),
                  SizedBox(width: context.rw(10)),
                  Expanded(
                    child: Text(
                      'my_visits.inventory.instruction'.tr,
                      style: TextStyle(
                          fontSize: context.rsp(12),
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(context.rw(16)),
                itemCount: _items.length,
                separatorBuilder: (_, __) => SizedBox(height: context.rh(12)),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _StockItemAuditCard(
                    item: item,
                    onStatusChanged: (status) {
                      HapticFeedback.selectionClick();
                      setState(() => item.status = status);
                      // Persist on every tap rather than on submit: the whole
                      // point is surviving an interruption, and an interruption
                      // never waits for the rep to reach the submit button.
                      widget.onProgressChanged?.call(_progress);
                    },
                  );
                },
              ),
            ),

            // Bottom sticky submit.
            Container(
              padding: EdgeInsets.all(context.rw(16)),
              decoration: BoxDecoration(
                color: colors.card,
                border: Border(top: BorderSide(color: colors.border)),
                boxShadow: colors.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress, so an incomplete submit button explains itself
                  // rather than just looking broken.
                  Text(
                    'my_visits.inventory.progress'.trParams({
                      'done': _assessed,
                      'total': _items.length,
                    }),
                    style: TextStyle(
                      fontSize: context.rsp(11.5),
                      fontWeight: FontWeight.w700,
                      color: _complete ? colors.success : colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: context.rh(8)),
                  ElevatedButton.icon(
                    // Disabled until every item has been judged — see the note
                    // on `DepotStockItem.status`.
                    onPressed: _complete
                        ? () {
                            HapticFeedback.mediumImpact();
                            widget.onSubmit();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      disabledBackgroundColor: colors.border,
                      disabledForegroundColor: colors.textDisabled,
                      minimumSize: Size(double.infinity, context.rh(48)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.rr(12))),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(
                      'my_visits.inventory.submit'.tr,
                      style: TextStyle(
                          fontSize: context.rsp(15),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
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
    required this.onStatusChanged,
  });

  final DepotStockItem item;
  final ValueChanged<StockStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final chosen = item.status;

    return Container(
      padding: EdgeInsets.all(context.rw(14)),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(14)),
        // An unjudged row carries a plain border; a judged one takes the tint
        // of its level, so the rep can see what is still outstanding by
        // scrolling rather than by reading every card.
        border: Border.all(
          color: chosen == null
              ? colors.border
              : chosen.color(context).withValues(alpha: 0.45),
          width: chosen == null ? 1 : 1.4,
        ),
        boxShadow: colors.cardShadow,
      ),
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
            '${'my_visits.inventory.unit'.tr}: ${item.unit}',
            style: TextStyle(
                fontSize: context.rsp(11), color: colors.textSecondary),
          ),
          SizedBox(height: context.rh(12)),
          Row(
            children: [
              for (final level in StockStatus.values) ...[
                Expanded(
                  child: _LevelOption(
                    level: level,
                    selected: chosen == level,
                    onTap: () => onStatusChanged(level),
                  ),
                ),
                if (level != StockStatus.values.last)
                  SizedBox(width: context.rw(8)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the three level choices.
class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final StockStatus level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tint = level.color(context);

    return Semantics(
      button: true,
      selected: selected,
      label: level.labelKey.tr,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.rr(10)),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          // 52dp tall: this is tapped one-handed, often with gloves on, by
          // someone standing in a depot aisle.
          constraints: BoxConstraints(minHeight: context.rh(52)),
          padding: EdgeInsets.symmetric(
              horizontal: context.rw(6), vertical: context.rh(8)),
          decoration: BoxDecoration(
            color: selected
                ? tint.withValues(alpha: 0.14)
                : colors.canvas.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(context.rr(10)),
            border: Border.all(
              color: selected ? tint : colors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                level.icon,
                size: context.rr(17),
                color: selected ? tint : colors.iconMuted,
              ),
              SizedBox(height: context.rh(3)),
              Text(
                level.labelKey.tr,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.rsp(10.5),
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? tint : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
