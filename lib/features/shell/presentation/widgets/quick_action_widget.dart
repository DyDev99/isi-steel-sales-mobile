import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/animations/animated_card.dart';
import 'package:isi_steel_sales_mobile/core/animations/app_animations.dart';
import 'package:isi_steel_sales_mobile/core/animations/fade_slide_transition.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/domain/entities/coach_action.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/app_coach.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_state.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_form_sheet.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/depot_selection_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/territory/territory_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/add_customer_bottom_sheet.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  // ---- Business logic (unchanged) ---------------------------------------

  void _startNewOrder(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: TerritoryScreen.routeName),
      builder: (_) => const TerritoryScreen(),
    ));
  }

  Future<void> _addLead(BuildContext context) async {
    final created = await showLeadFormSheet(context: context);
    if (created != null && context.mounted) {
      context.read<PipelineBloc>().add(LeadCreated(created));
    }
  }

  void _addCustomerFromWon(BuildContext context) {
    final state = context.read<PipelineBloc>().state;
    if (state is PipelineLoaded) {
      // Filters and extracts data exclusively from the 'Won' board column.
      final wonLeads = state.columns[PipelineStage.won] ?? [];

      showModalBottomSheet(
        context: context,
        backgroundColor: context.appColors.surfaceSoft,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (_) => AddCustomerBottomSheet(wonLeads: wonLeads),
      );
    }
  }

  void _openDepotStock(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: DepotSelectionScreen.routeName),
      builder: (_) => const DepotSelectionScreen(),
    ));
  }

  // ---- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionHeader('QUICK ACTIONS', letterSpacing: 1.2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FadeSlideIn(
                  delay: FadeSlideIn.staggerDelay(0),
                  child: CoachKeys.wrap(
                    CoachKeys.newQuote,
                    child: _QuickActionCard(
                      icon: Icons.assignment_outlined,
                      accent: const Color(0xFF4C9AFF),
                      label: 'New quote',
                      onTap: () => _startNewOrder(context),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: FadeSlideIn(
                  delay: FadeSlideIn.staggerDelay(1),
                  child: CoachKeys.wrap(
                    CoachKeys.newLead,
                    child: _QuickActionCard(
                      icon: Icons.bar_chart_rounded,
                      accent: const Color(0xFF36B37E),
                      label: 'New lead',
                      onTap: () {
                        AppCoach.notify(CoachAction.createLead);
                        _addLead(context);
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: FadeSlideIn(
                  delay: FadeSlideIn.staggerDelay(2),
                  child: CoachKeys.wrap(
                    CoachKeys.depotStock,
                    child: _QuickActionCard(
                      icon: Icons.inventory_2_outlined,
                      accent: const Color(0xFFFFAB00),
                      label: 'Depot stock',
                      onTap: () => _openDepotStock(context),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: FadeSlideIn(
                  delay: FadeSlideIn.staggerDelay(3),
                  child: CoachKeys.wrap(
                    CoachKeys.addCustomer,
                    child: _QuickActionCard(
                      icon: Icons.person_add_alt_1_outlined,
                      accent: const Color(0xFF6554C0),
                      label: 'Add customer',
                      onTap: () => _addCustomerFromWon(context),
                    ),
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedCard(
      onTap: onTap,
      semanticLabel: label,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: context.appColors.border),
      pressedScale: AppScale.pressedAction,
      splashColor: accent.withValues(alpha: 0.14),
      highlightColor: accent.withValues(alpha: 0.06),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      builder: (context, pressed, hovered) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: pressed ? 0.92 : 1.0,
              duration: AppDurations.pressUp,
              curve: AppCurves.bounce,
              child: Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: accent, size: 20.r),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.letterSpacing = 1.2});

  final String text;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ??
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: letterSpacing,
          color: color,
        ),
      ),
    );
  }
}
