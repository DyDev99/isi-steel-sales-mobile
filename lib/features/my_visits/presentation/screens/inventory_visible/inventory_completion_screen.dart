import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/animations/steelforce_success_animation.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

class InventoryCompletionScreen extends StatelessWidget {
  const InventoryCompletionScreen({
    super.key,
    required this.outletName,
    required this.onCreateQuotation,
    required this.onEndVisit,
  });

  /// `RouteSettings.name`, and the resume key for this step.
  ///
  /// Without an identity of its own this screen was invisible to the resume
  /// dispatcher: the pointer still read "inventory audit", so a rep who
  /// submitted the count and then left was sent back to walk the racks a
  /// second time. Recording the completion step is what makes finished work
  /// stay finished.
  static const String routeName = 'my-visits-inventory-completion';

  final String outletName;
  final VoidCallback onCreateQuotation;
  final VoidCallback onEndVisit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.rw(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // The moment the whole step builds to. Sized generously — this
              // was a 48pt tick in an 80pt circle, which is a status indicator,
              // not a completion. A confirmation screen has one job and this is
              // it, so it gets the room.
              SteelForceSuccessAnimation(
                size: context.rr(180),
                // Brand blue rather than the usual success green: it matches
                // the SteelForce success artwork, and a check reads as
                // confirmation regardless of hue.
                primaryColor: scheme.primary,
                // Announced for screen readers — without a label the mark is
                // decorative and a rep hears only the heading beneath it.
                semanticLabel: 'my_visits.inventory.completion.title'.tr,
              ),
              SizedBox(height: context.rh(4)),

              // Success Heading
              Text(
                'my_visits.inventory.completion.title'.tr,
                style: TextStyle(
                  fontSize: context.rsp(20),
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.rh(8)),
              Text(
                // `trParams`, not string interpolation: the outlet name sits
                // in a different position in Khmer, and a concatenated
                // sentence cannot be reordered by a translator.
                'my_visits.inventory.completion.subtitle'
                    .trParams({'outlet': outletName}),
                style: TextStyle(
                  fontSize: context.rsp(13),
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Decision Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.rw(16)),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(context.rr(16)),
                  border: Border.all(color: colors.border),
                  boxShadow: colors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'my_visits.inventory.completion.next_question'.tr,
                      style: TextStyle(
                        fontSize: context.rsp(13.5),
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.rh(16)),

                    // Primary Action 1: Create Quotation
                    ElevatedButton.icon(
                      onPressed: onCreateQuotation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: context.rh(14)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.rr(12)),
                        ),
                      ),
                      icon: const Icon(Icons.request_quote_rounded),
                      label: Text(
                        // Reused rather than duplicated: the Route Information
                        // screen already ships this exact action label, and two
                        // keys for one button is how the two drift apart.
                        'my_visits.route_info.create_quotation'.tr,
                        style: TextStyle(
                          fontSize: context.rsp(15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: context.rh(10)),

                    // Primary Action 2: End Visit
                    OutlinedButton.icon(
                      onPressed: onEndVisit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(
                            color: scheme.error.withValues(alpha: 0.5)),
                        padding: EdgeInsets.symmetric(vertical: context.rh(14)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.rr(12)),
                        ),
                      ),
                      icon: const Icon(Icons.stop_circle_rounded),
                      label: Text(
                        'my_visits.inventory.completion.complete_visit'.tr,
                        style: TextStyle(
                          fontSize: context.rsp(15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
