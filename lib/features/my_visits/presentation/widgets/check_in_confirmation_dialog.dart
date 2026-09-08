import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/check_in_location_verifier.dart';

/// What the rep chose in [CheckInConfirmationDialog].
enum CheckInConfirmation {
  /// Inside the area and confirmed — proceed with the check-in.
  confirmed,

  /// Outside the area, and the rep chose to proceed. The caller must collect a
  /// written reason before dispatching — this value alone never checks anyone
  /// in.
  withReason,
}

/// Location verification, shown before a check-in is dispatched.
///
/// ## Why a confirmation step at all
///
/// The check-in is the evidence that a visit happened where it claims to, and
/// it is not reversible from the device. Showing the rep the distance their
/// check-in will carry — before it is written — is what makes that number
/// something they agreed to rather than something measured behind them.
///
/// ## Two actions, and what separates them
///
/// Inside the area, **Confirm Check-In** proceeds with no further questions:
/// the rule is satisfied, and asking a rep standing in the right place to
/// justify themselves is friction with nothing behind it.
///
/// Outside it, the primary action becomes **Continue with Reason** — the rep is
/// not blocked, but the check-in has to carry an explanation. That reason is
/// collected next (`RemoteCheckInSheet`) and travels on the check-in row
/// itself, so an out-of-area visit is attributable rather than merely
/// permitted. **Confirm Check-In is absent here, not disabled**: a greyed-out
/// primary action reads as "this ought to work", and the forward path is a
/// different one, not the same one withheld.
///
/// Returns null when the rep dismissed it.
class CheckInConfirmationDialog extends StatelessWidget {
  const CheckInConfirmationDialog({
    super.key,
    required this.outletName,
    required this.verdict,
  });

  final String outletName;
  final CheckInLocationVerdict verdict;

  static Future<CheckInConfirmation?> show(
    BuildContext context, {
    required String outletName,
    required CheckInLocationVerdict verdict,
  }) =>
      showDialog<CheckInConfirmation>(
        context: context,
        // The rep must answer it: this decides whether a durable record is
        // written, and a dialog dismissed by a stray tap on the scrim leaves
        // them unsure whether they checked in.
        barrierDismissible: false,
        builder: (_) => CheckInConfirmationDialog(
          outletName: outletName,
          verdict: verdict,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final within = verdict.isWithinRadius;

    // Amber, not red, when outside. The rep has done nothing wrong — they are
    // standing somewhere the rule does not cover yet, and red reads as a fault.
    final accent = within ? colors.success : colors.warning;

    final (String titleKey, String bodyKey) = switch (verdict) {
      _ when !verdict.hasOutletLocation => (
          'my_visits.check_in_verification.no_outlet_title',
          'my_visits.check_in_verification.no_outlet_body',
        ),
      _ when !verdict.hasDeviceFix => (
          'my_visits.check_in_verification.no_fix_title',
          'my_visits.check_in_verification.no_fix_body',
        ),
      _ when within => (
          'my_visits.check_in_verification.within_title',
          'my_visits.check_in_verification.within_body',
        ),
      _ => (
          'my_visits.check_in_verification.outside_title',
          'my_visits.check_in_verification.outside_body',
        ),
    };

    return Dialog(
      backgroundColor: colors.card,
      insetPadding: EdgeInsets.symmetric(horizontal: context.rw(28)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.rr(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            context.rw(20), context.rh(22), context.rw(20), context.rh(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon carries the verdict alongside the colour — amber and green
            // are the pair a colour-blind rep cannot separate (FS-A11Y-3).
            Container(
              width: context.rr(56),
              height: context.rr(56),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                switch (verdict) {
                  _ when !verdict.isMeasurable =>
                    Icons.location_searching_rounded,
                  _ when within => Icons.where_to_vote_rounded,
                  _ => Icons.location_off_rounded,
                },
                color: accent,
                size: context.rr(28),
              ),
            ),
            SizedBox(height: context.rh(6)),
            Text(
              'my_visits.check_in_verification.title'.tr,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: context.rsp(11),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: context.rh(10)),

            Text(
              titleKey.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(17),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: context.rh(6)),
            Text(
              outletName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: context.rsp(13),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.rh(14)),

            if (verdict.isMeasurable)
              _Measurements(verdict: verdict, accent: accent),

            SizedBox(height: context.rh(12)),
            Text(
              bodyKey.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: context.rsp(12.5),
                height: 1.45,
              ),
            ),
            SizedBox(height: context.rh(20)),

            // Wrap, not Row: at large text scales "Confirm Check-In" beside
            // "Cancel" cannot share a line, and a clipped primary action on a
            // decision dialog is not a cosmetic problem.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: context.rw(10),
              runSpacing: context.rh(8),
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rw(18), vertical: context.rh(12)),
                  ),
                  child: Text('common.cancel'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (within)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pop(CheckInConfirmation.confirmed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.rw(18), vertical: context.rh(12)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.rr(12)),
                      ),
                    ),
                    icon: Icon(Icons.check_rounded, size: context.rr(18)),
                    label: Text(
                      'my_visits.check_in_verification.confirm'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                else if (verdict.isMeasurable)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pop(CheckInConfirmation.withReason),
                    style: ElevatedButton.styleFrom(
                      // Amber, matching the verdict: this is a permitted step
                      // past the rule, not the ordinary path.
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.rw(18), vertical: context.rh(12)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.rr(12)),
                      ),
                    ),
                    icon: Icon(Icons.edit_note_rounded, size: context.rr(18)),
                    label: Text(
                      'my_visits.check_in_verification.continue_with_reason'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Distance and the allowed radius, side by side — the two numbers the verdict
/// is derived from, so the rep can see *why* rather than being told.
class _Measurements extends StatelessWidget {
  const _Measurements({required this.verdict, required this.accent});

  final CheckInLocationVerdict verdict;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Whole metres, through intl: a rep does not need centimetres, and the
    // separator is locale-dependent once the figure passes a thousand.
    final format = NumberFormat.decimalPattern(context.languageCode)
      ..maximumFractionDigits = 0;

    String metres(double v) => 'my_visits.check_in_verification.meters'
        .trParams({'value': format.format(v)});

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rw(14), vertical: context.rh(12)),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(context.rr(14)),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: 'my_visits.check_in_verification.distance_label'.tr,
              value: metres(verdict.distanceMeters),
              // The figure the verdict turns on, so it carries the accent.
              valueColor: accent,
              emphasize: true,
            ),
          ),
          Container(
            width: 1,
            height: context.rh(34),
            color: colors.divider,
            margin: EdgeInsets.symmetric(horizontal: context.rw(12)),
          ),
          Expanded(
            child: _Metric(
              label: 'my_visits.check_in_verification.radius_label'.tr,
              value: metres(verdict.radiusMeters),
              valueColor: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 2,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: context.rsp(10.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.rh(3)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: context.rsp(emphasize ? 19 : 15),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
