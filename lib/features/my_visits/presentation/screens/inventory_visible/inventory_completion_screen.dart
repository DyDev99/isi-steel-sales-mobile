import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

class InventoryCompletionScreen extends StatelessWidget {
  const InventoryCompletionScreen({
    super.key,
    required this.outletName,
    required this.onCreateQuotation,
    required this.onEndVisit,
  });

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

              // Success Icon Badge
              Container(
                width: context.rr(80),
                height: context.rr(80),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colors.success,
                  size: context.rr(48),
                ),
              ),
              SizedBox(height: context.rh(20)),

              // Success Heading
              Text(
                'Inventory Audit Submitted!',
                style: TextStyle(
                  fontSize: context.rsp(20),
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.rh(8)),
              Text(
                'Depot stock records for $outletName have been successfully updated.',
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
                      'What would you like to do next?',
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
                        'Create Quotation', // go to quotation creation screen
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
                        'End Visit', // Go back to dashboard
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
