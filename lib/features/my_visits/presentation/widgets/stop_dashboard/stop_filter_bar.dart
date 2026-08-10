import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/stop_dashboard_state.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Horizontally-scrollable status filter chips for the Stop Dashboard.
class StopFilterBar extends StatelessWidget {
  const StopFilterBar(
      {super.key, required this.selected, required this.onSelected});

  final StopFilter selected;
  final ValueChanged<StopFilter> onSelected;

  static const _labelKeys = <StopFilter, String>{
    StopFilter.all: 'my_visits.stop_dashboard.filter_all',
    StopFilter.pending: 'my_visits.stop_dashboard.filter_pending',
    StopFilter.checkedIn: 'my_visits.stop_dashboard.filter_checked_in',
    StopFilter.completed: 'my_visits.stop_dashboard.filter_completed',
    StopFilter.skipped: 'my_visits.stop_dashboard.filter_skipped',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: context.rh(34),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: StopFilter.values.length,
        separatorBuilder: (_, __) => SizedBox(width: context.rw(8)),
        itemBuilder: (context, i) {
          final filter = StopFilter.values[i];
          final isSelected = filter == selected;
          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              HapticFeedback.selectionClick();
              onSelected(filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: context.rw(14)),
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : colors.surfaceSoft,
                borderRadius: BorderRadius.circular(context.rr(20)),
                border: Border.all(
                    color: isSelected ? scheme.primary : colors.border),
              ),
              child: Text(
                _labelKeys[filter]!.tr,
                style: TextStyle(
                  color: isSelected ? scheme.onPrimary : colors.textSecondary,
                  fontSize: context.rsp(12),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
