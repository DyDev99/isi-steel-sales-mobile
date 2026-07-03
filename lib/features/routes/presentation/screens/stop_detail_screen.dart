import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_note.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/visit_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/checkin_status_banner.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/collections_form.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/order_capture_form.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/returns_form.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/stock_update_form.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/visit_timeline.dart';

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
        backgroundColor: Vibe.bgSoft,
        title: const Text('Add Note', style: TextStyle(color: Vibe.text)),
        content: TextField(controller: controller, autofocus: true, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
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

  void _addMockPhoto(BuildContext context, String stopId, {bool isSignature = false}) {
    context.read<VisitCubit>().addPhoto(VisitPhoto(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          stopId: stopId,
          url: 'https://picsum.photos/seed/$stopId${DateTime.now().millisecondsSinceEpoch}/400/300',
          caption: isSignature ? 'Customer signature' : 'Visit photo',
          takenAt: DateTime.now(),
          isSignature: isSignature,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: const Text('Visit', style: TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
        builder: (context, state) {
          if (state is! ActiveRouteReady || !state.hasCurrentStop) {
            return const Center(child: Text('No stop selected', style: TextStyle(color: Vibe.muted)));
          }
          final stop = state.route.stops[state.currentStopIndex];
          _ensureVisitLoaded(stop);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(stop.customer.name, style: const TextStyle(color: Vibe.text, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(stop.customer.address, style: const TextStyle(color: Vibe.muted, fontSize: 12.5)),
              const SizedBox(height: 4),
              Text('${stop.customer.contact} · ${stop.customer.phone}', style: const TextStyle(color: Vibe.muted, fontSize: 12.5)),
              const SizedBox(height: 16),

              CheckinStatusBanner(
                insideGeofence: state.insideGeofence,
                distanceMeters: state.distanceMeters,
                blockedReason: state.blockedCheckInReason,
                warnings: state.checkInWarnings,
              ),
              const SizedBox(height: 16),

              if (stop.status != VisitStatus.checkedIn && stop.status != VisitStatus.checkedOut)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.read<ActiveRouteBloc>().add(const CheckInRequested()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Vibe.violet,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Check In'),
                  ),
                ),

              if (stop.status == VisitStatus.checkedIn) ...[
                _Section(
                  title: 'Capture',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionChip(label: 'Order', icon: Icons.shopping_cart_rounded, onTap: () async {
                        final line = await showOrderCaptureSheet(context: context, stopId: stop.id);
                        if (line != null && context.mounted) context.read<VisitCubit>().addOrderLine(line);
                      }),
                      _ActionChip(label: 'Stock', icon: Icons.inventory_2_rounded, onTap: () async {
                        final update = await showStockUpdateSheet(context: context, stopId: stop.id);
                        if (update != null && context.mounted) context.read<VisitCubit>().addStockUpdate(update);
                      }),
                      _ActionChip(label: 'Return', icon: Icons.undo_rounded, onTap: () async {
                        final ret = await showReturnsSheet(context: context, stopId: stop.id);
                        if (ret != null && context.mounted) context.read<VisitCubit>().addReturn(ret);
                      }),
                      _ActionChip(label: 'Collection', icon: Icons.payments_rounded, onTap: () async {
                        final collection = await showCollectionsSheet(context: context, stopId: stop.id);
                        if (collection != null && context.mounted) context.read<VisitCubit>().addCollection(collection);
                      }),
                      _ActionChip(label: 'Note', icon: Icons.note_alt_rounded, onTap: () => _addNote(context, stop.id)),
                      _ActionChip(
                          label: 'Photo', icon: Icons.photo_camera_rounded, onTap: () => _addMockPhoto(context, stop.id)),
                      _ActionChip(
                          label: 'Signature',
                          icon: Icons.draw_rounded,
                          onTap: () => _addMockPhoto(context, stop.id, isSignature: true)),
                    ],
                  ),
                ),
                _Section(
                  title: 'Visit Timeline',
                  child: BlocBuilder<VisitCubit, VisitState>(
                    builder: (context, visitState) => VisitTimeline(
                      entries: buildVisitTimeline(stop, visitState is VisitLoaded ? visitState.data : null),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.read<ActiveRouteBloc>().add(const CheckOutRequested('Visit completed')),
                    child: const Text('Check Out'),
                  ),
                ),
              ],

              if (stop.status == VisitStatus.checkedOut) ...[
                const SizedBox(height: 8),
                const Text('Visit completed', style: TextStyle(color: Vibe.success, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ActiveRouteBloc>().add(const NextStopRequested());
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Vibe.violet,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Next Stop'),
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
            Text(title, style: const TextStyle(color: Vibe.text, fontSize: 14.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Vibe.primaryLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Vibe.violet.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Vibe.violet),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Vibe.violet, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
