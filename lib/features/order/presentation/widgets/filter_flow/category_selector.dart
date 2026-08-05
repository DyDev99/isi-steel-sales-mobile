import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/filter_flow_transition.dart';

/// 4-column grid selector featuring a 3D tactile card design with dual ambient shadows,
/// bevel gradients, and a premium "Read More" expander button.
class CategorySelector extends StatefulWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.onSelect,
    this.selectedCategoryId,
  });

  final List<Category> categories;
  final ValueChanged<Category> onSelect;
  final String? selectedCategoryId;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  bool _isExpanded = false;

  // 2 rows * 4 columns = 8 items max initially
  static const int _maxInitialItems = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final hasMore = widget.categories.length > _maxInitialItems;
    final visibleCategories = (_isExpanded || !hasMore)
        ? widget.categories
        : widget.categories.take(_maxInitialItems).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
          itemCount: visibleCategories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 0.80,
          ),
          itemBuilder: (context, index) {
            final category = visibleCategories[index];
            return FilterFlowStaggeredItem(
              index: index,
              child: _CategoryTile(
                category: category,
                selected: category.id == widget.selectedCategoryId,
                onTap: () => widget.onSelect(category),
              ),
            );
          },
        ),
        if (hasMore) ...[
          SizedBox(height: 8.h),
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(20.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.25),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.08),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 1.r,
                        offset: Offset(0, -1.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'Show Less' : 'Read More',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16.sp,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: FilterFlowTransition.duration,
      curve: FilterFlowTransition.curve,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [
                  scheme.primary.withValues(alpha: 0.16),
                  scheme.primary.withValues(alpha: 0.04),
                ]
              : [
                  colors.card,
                  colors.surfaceSoft,
                ],
        ),
        border: Border.all(
          color: selected
              ? scheme.primary
              : colors.border.withValues(alpha: 0.8),
          width: selected ? 1.5.w : 1.w,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.22),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 2.r,
                  offset: Offset(0, -1.h),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 1.r,
                  offset: Offset(0, -1.h),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Embossed Icon Badge
                Container(
                  padding: EdgeInsets.all(7.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: selected
                          ? [
                              scheme.primary.withValues(alpha: 0.22),
                              scheme.primary.withValues(alpha: 0.08),
                            ]
                          : [
                              colors.card,
                              colors.border.withValues(alpha: 0.25),
                            ],
                    ),
                    border: Border.all(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.4)
                          : colors.border.withValues(alpha: 0.5),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    _iconFor(category.icon ?? category.code),
                    size: 20.sp,
                    color: selected ? scheme.primary : colors.iconMuted,
                  ),
                ),
                SizedBox(height: 6.h),
                // Category Text Label
                Text(
                  context.localized(category.name),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? scheme.primary : colors.textPrimary,
                    fontSize: 10.5.sp,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Product-specific icon mapping for ISI Steel & building material product lines.
  static IconData _iconFor(String name) {
    final n = name.toLowerCase();

    // 1. Roofing, Tiles, Panels & Trusses
    if (n.contains('tile') || n.contains('wave')) return Icons.roofing_rounded;
    if (n.contains('deck') || n.contains('panel')) return Icons.view_quilt_rounded;
    if (n.contains('truss') || n.contains('palm') || n.contains('inno')) {
      return Icons.architecture_rounded;
    }
    if (n.contains('roof')) return Icons.roofing_rounded;

    // 2. Flashing, Gutters & Ridge Caps
    if (n.contains('gutter') || n.contains('flashing') || n.contains('ridge') || n.contains('cap')) {
      return Icons.border_top_rounded;
    }

    // 3. Fasteners, Hardware, Screws & Tools
    if (n.contains('screw') || n.contains('bolt') || n.contains('fastener')) {
      return Icons.build_circle_outlined;
    }
    if (n.contains('weld') || n.contains('electrode')) return Icons.flash_on_rounded;
    if (n.contains('hardware') || n.contains('tool')) return Icons.hardware_rounded;

    // 4. Pipes & Tubing (Round, Square, Rectangular)
    if (n.contains('square') || n.contains('box pipe')) return Icons.crop_square_rounded;
    if (n.contains('pipe') || n.contains('tube') || n.contains('hollow')) {
      return Icons.circle_outlined;
    }

    // 5. Structural Steel (Beams, Columns, Purlins, Channels, Angle Bars)
    if (n.contains('h-beam') || n.contains('i-beam') || n.contains('beam')) {
      return Icons.table_rows_rounded;
    }
    if (n.contains('purlin') || n.contains('c-purlin') || n.contains('z-purlin') || n.contains('cam')) {
      return Icons.view_week_rounded;
    }
    if (n.contains('angle') || n.contains('channel')) return Icons.turn_right_rounded;
    if (n.contains('structural') || n.contains('steel')) return Icons.grid_goldenratio;

    // 6. Rebar, Deformed Bars & Wire Mesh
    if (n.contains('mesh') || n.contains('fence') || n.contains('net')) {
      return Icons.grid_4x4_rounded;
    }
    if (n.contains('rebar') || n.contains('deformed') || n.contains('bar') || n.contains('rod')) {
      return Icons.straighten_rounded;
    }

    // 7. Coils, Flat Sheets & Plates
    if (n.contains('coil') || n.contains('roll')) return Icons.motion_photos_on_rounded;
    if (n.contains('checkered') || n.contains('plate')) return Icons.grid_on_rounded;
    if (n.contains('flat') || n.contains('sheet') || n.contains('slitted')) {
      return Icons.layers_outlined;
    }

    // 8. Ceiling, Drywall & Interior
    if (n.contains('ceiling') || n.contains('drywall') || n.contains('stud') || n.contains('track')) {
      return Icons.space_dashboard_rounded;
    }
    if (n.contains('interior')) return Icons.chair_outlined;

    // 9. Construction / General Building
    if (n.contains('construction') || n.contains('foundation')) {
      return Icons.foundation_outlined;
    }

    // Fallback icon for unrecognized product codes
    return Icons.inventory_2_outlined;
  }
}