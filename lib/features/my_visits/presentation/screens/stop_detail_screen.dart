import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_note.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/visit_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/checkin_status_banner.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/collections_form.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/order_capture_form.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/returns_form.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stock_update_form.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/visit_timeline.dart';

/// The visit screen for whichever stop `ActiveRouteBloc.currentStopIndex`
/// points to — check-in (with live geofence/fraud status), then all offline
/// capture (orders/stock/returns/collections/notes/photos), then check-out.
class StopDetailScreen extends StatefulWidget {
  const StopDetailScreen({super.key});

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  String? _loadedFor;

  void _ensureVisitLoaded(RouteStop stop) {
    if (_loadedFor == stop.id) return;
    _loadedFor = stop.id;
    context.read<VisitCubit>().load(stop.id);
  }

  Future<void> _addNote(BuildContext context, String stopId) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surfaceSoft,
        title: Text('common.add_note'.tr,
            style: TextStyle(color: context.appColors.textPrimary)),
        content:
            TextField(controller: controller, autofocus: true, maxLines: 3),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr)),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text('common.save'.tr)),
        ],
      ),
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    context.read<VisitCubit>().addNote(VisitNote(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          stopId: stopId,
          type: VisitNoteType.general,
          text: text,
          createdAt: DateTime.now(),
        ));
  }

  void _addMockPhoto(BuildContext context, String stopId,
      {bool isSignature = false}) {
    context.read<VisitCubit>().addPhoto(VisitPhoto(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          stopId: stopId,
          url:
              'https://picsum.photos/seed/$stopId${DateTime.now().millisecondsSinceEpoch}/400/300',
          caption: isSignature
              ? 'my_visits.stop.customer_signature'.tr
              : 'my_visits.stop.visit_photo'.tr,
          takenAt: DateTime.now(),
          isSignature: isSignature,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text('customers.visit'.tr,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ),
      body: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
        builder: (context, state) {
          if (state is! ActiveRouteReady || !state.hasCurrentStop) {
            return Center(
                child: Text('my_visits.flow.no_stop'.tr,
                    style: TextStyle(color: colors.textSecondary)));
          }
          final stop = state.route.stops[state.currentStopIndex];
          _ensureVisitLoaded(stop);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(stop.customer.name,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(stop.customer.address,
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 4),
              Text('${stop.customer.contact} · ${stop.customer.phone}',
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 16),
              CheckinStatusBanner(
                insideGeofence: state.insideGeofence,
                distanceMeters: state.distanceMeters,
                blockedReason: state.blockedCheckInReason,
                warnings: state.checkInWarnings,
              ),
              const SizedBox(height: 16),
              if (stop.status != VisitStatus.checkedIn &&
                  stop.status != VisitStatus.checkedOut)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    // Locked until the live GPS position is inside this stop's
                    // geofence circle (state.insideGeofence, fed by
                    // GeofenceStatusChanged in ActiveRouteScreen's listener).
                    onPressed: state.insideGeofence
                        ? () => context
                            .read<ActiveRouteBloc>()
                            .add(const CheckInRequested())
                        : null,
                    icon: Icon(
                        state.insideGeofence
                            ? Icons.check_circle_rounded
                            : Icons.lock_rounded,
                        size: 20),
                    label: Text(
                      state.insideGeofence
                          ? 'my_visits.stop.check_in'.tr
                          : 'my_visits.stop.get_closer'.trParams({
                              'distance':
                                  state.distanceMeters.toStringAsFixed(0)
                            }),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      disabledBackgroundColor: colors.border,
                      disabledForegroundColor: colors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              if (stop.status == VisitStatus.checkedIn) ...[
                _Section(
                  title: 'my_visits.stop.capture'.tr,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionChip(
                          label: 'my_visits.stop.order'.tr,
                          icon: Icons.shopping_cart_rounded,
                          onTap: () async {
                            final line = await showOrderCaptureSheet(
                                context: context, stopId: stop.id);
                            if (line != null && context.mounted) {
                              context.read<VisitCubit>().addOrderLine(line);
                            }
                          }),
                      _ActionChip(
                          label: 'my_visits.stop.stock'.tr,
                          icon: Icons.inventory_2_rounded,
                          onTap: () async {
                            final update = await showStockUpdateSheet(
                                context: context, stopId: stop.id);
                            if (update != null && context.mounted) {
                              context.read<VisitCubit>().addStockUpdate(update);
                            }
                          }),
                      _ActionChip(
                          label: 'my_visits.stop.return_label'.tr,
                          icon: Icons.undo_rounded,
                          onTap: () async {
                            final ret = await showReturnsSheet(
                                context: context, stopId: stop.id);
                            if (ret != null && context.mounted) {
                              context.read<VisitCubit>().addReturn(ret);
                            }
                          }),
                      _ActionChip(
                          label: 'my_visits.stop.collection'.tr,
                          icon: Icons.payments_rounded,
                          onTap: () async {
                            final collection = await showCollectionsSheet(
                                context: context, stopId: stop.id);
                            if (collection != null && context.mounted) {
                              context
                                  .read<VisitCubit>()
                                  .addCollection(collection);
                            }
                          }),
                      _ActionChip(
                          label: 'my_visits.stop.note'.tr,
                          icon: Icons.note_alt_rounded,
                          onTap: () => _addNote(context, stop.id)),
                      _ActionChip(
                          label: 'my_visits.stop.photo'.tr,
                          icon: Icons.photo_camera_rounded,
                          onTap: () => _addMockPhoto(context, stop.id)),
                      _ActionChip(
                          label: 'my_visits.stop.signature'.tr,
                          icon: Icons.draw_rounded,
                          onTap: () => _addMockPhoto(context, stop.id,
                              isSignature: true)),
                    ],
                  ),
                ),
                _Section(
                  title: 'my_visits.stop.visit_timeline'.tr,
                  child: BlocBuilder<VisitCubit, VisitState>(
                    builder: (context, visitState) => VisitTimeline(
                      entries: buildVisitTimeline(stop,
                          visitState is VisitLoaded ? visitState.data : null),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.read<ActiveRouteBloc>().add(
                        CheckOutRequested('my_visits.stop.visit_completed'.tr)),
                    child: Text('my_visits.stop.check_out'.tr),
                  ),
                ),
              ],
              if (stop.status == VisitStatus.checkedOut) ...[
                const SizedBox(height: 8),
                Text('my_visits.stop.visit_completed'.tr,
                    style: TextStyle(
                        color: colors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<ActiveRouteBloc>()
                          .add(const NextStopRequested());
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('my_visits.stop.next_stop'.tr),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceStrong.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: scheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
