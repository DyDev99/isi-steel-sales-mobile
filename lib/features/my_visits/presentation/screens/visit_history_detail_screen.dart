import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/visit_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/visit_history_card.dart'
    show statusStyle;
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/visit_map_preview.dart';

/// Read-only detail view for one visit history record. UI only — every value
/// shown here comes from the static [VisitRecord] passed in; nothing is
/// fetched, saved, or synced.
class VisitHistoryDetailScreen extends StatelessWidget {
  const VisitHistoryDetailScreen({super.key, required this.visit});

  static const routeName = 'visit-history-detail';

  final VisitRecord visit;

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = statusStyle(context, visit.status);
    final timeFmt = DateFormat('h:mm a');
    final dateFmt = DateFormat('MMM d, y');
    final duration = visit.duration;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text('my_visits.history.details_title'.tr,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          VisitMapPreview(
              latitude: visit.latitude,
              longitude: visit.longitude,
              height: 170,
              borderRadius: 16),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(visit.customerName,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.place_rounded, size: 15, color: colors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(visit.address,
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 20),
          _InfoCard(
            children: [
              _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: dateFmt.format(visit.visitDate)),
              if (visit.checkInTime != null)
                _InfoRow(
                  icon: Icons.login_rounded,
                  label:
                      '${'my_visits.history.checked_in'.tr}: ${timeFmt.format(visit.checkInTime!)}',
                ),
              if (visit.checkOutTime != null)
                _InfoRow(
                  icon: Icons.logout_rounded,
                  label:
                      '${'my_visits.history.checked_out'.tr}: ${timeFmt.format(visit.checkOutTime!)}',
                ),
              if (duration != null)
                _InfoRow(
                  icon: Icons.timer_outlined,
                  label:
                      '${'my_visits.history.duration'.tr}: ${duration.inMinutes} min',
                ),
            ],
          ),
          if (visit.orderPlaced || visit.collectedAmount != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              children: [
                if (visit.orderPlaced)
                  _InfoRow(
                      icon: Icons.receipt_long_rounded,
                      label: 'my_visits.history.order_placed'.tr,
                      valueColor: scheme.primary),
                if (visit.collectedAmount != null)
                  _InfoRow(
                    icon: Icons.payments_rounded,
                    label:
                        '${'my_visits.history.collected_amount'.tr}: \$${visit.collectedAmount!.toStringAsFixed(2)}',
                    valueColor: colors.success,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text('my_visits.history.customer'.tr,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _InfoCard(
            children: [
              if (visit.phoneNumber != null)
                _InfoRow(icon: Icons.phone_rounded, label: visit.phoneNumber!),
            ],
          ),
          const SizedBox(height: 20),
          Text('my_visits.history.notes'.tr,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border)),
            child: Text(
              (visit.notes == null || visit.notes!.isEmpty)
                  ? 'my_visits.history.no_notes'.tr
                  : visit.notes!,
              style: TextStyle(
                  color:
                      visit.notes == null ? colors.textSecondary : colors.textPrimary,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          Text('my_visits.history.photos'.tr,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          visit.photoCount == 0
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border)),
                  child: Text('my_visits.history.no_photos'.tr,
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 13)),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visit.photoCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8),
                  itemBuilder: (_, __) => Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceStrong,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.image_rounded, color: scheme.primary),
                  ),
                ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appColors.border)),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.valueColor});
  final IconData icon;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: valueColor ?? colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: valueColor ?? colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
