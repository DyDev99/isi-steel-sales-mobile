import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/depot_info_screen.dart';

/// Gate the rep must pass through to resume a route: they must pick the
/// **route**, give a **reason**, and confirm a **date** before continuing. On
/// submit it hands back to [DepotInfoScreen] (with a resuming banner), from
/// which "Start Route" re-enters the guided flow. All three fields are required.
class ResumeRouteScreen extends StatefulWidget {
  const ResumeRouteScreen({
    super.key,
    required this.routes,
    this.initialRoute,
    this.syncCubit,
  });

  static const routeName = 'resume-route';

  final List<RoutePlan> routes;
  final RoutePlan? initialRoute;
  final RouteSyncCubit? syncCubit;

  @override
  State<ResumeRouteScreen> createState() => _ResumeRouteScreenState();
}

class _ResumeRouteScreenState extends State<ResumeRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  RoutePlan? _selectedRoute;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.initialRoute ??
        (widget.routes.isNotEmpty ? widget.routes.first : null);
    _selectedDate = _selectedRoute?.visitDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    // The route dropdown + date field are validated manually (they aren't
    // plain FormFields); the reason is validated by the Form.
    final formOk = _formKey.currentState?.validate() ?? false;
    if (_selectedRoute == null) {
      _snack('my_visits.resume.select_route'.tr);
      return;
    }
    if (_selectedDate == null) {
      _snack('my_visits.resume.select_date'.tr);
      return;
    }
    if (!formOk) return;

    final route = _selectedRoute!;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      settings: const RouteSettings(name: DepotInfoScreen.routeName),
      builder: (_) => DepotInfoScreen(
        route: route,
        routes: widget.routes,
        syncCubit: widget.syncCubit,
        resume: ResumeContext(
          reason: _reasonController.text.trim(),
          date: _selectedDate!,
        ),
      ),
    ));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'my_visits.resume.title'.tr,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                'my_visits.resume.subtitle'.tr,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Route (required)
              _FieldLabel('my_visits.resume.route_label'.tr),
              const SizedBox(height: 6),
              DropdownButtonFormField<RoutePlan>(
                initialValue: _selectedRoute,
                isExpanded: true,
                decoration: _decoration(context,
                    hint: 'my_visits.resume.route_hint'.tr,
                    icon: Icons.alt_route_rounded),
                items: [
                  for (final r in widget.routes)
                    DropdownMenuItem<RoutePlan>(
                      value: r,
                      child: Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                ],
                validator: (v) =>
                    v == null ? 'my_visits.resume.select_route'.tr : null,
                onChanged: (v) => setState(() {
                  _selectedRoute = v;
                  _selectedDate = v?.visitDate ?? _selectedDate;
                }),
              ),
              const SizedBox(height: 18),

              // Reason (required)
              _FieldLabel('my_visits.resume.reason_label'.tr),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                minLines: 2,
                textInputAction: TextInputAction.done,
                decoration: _decoration(context,
                    hint: 'my_visits.resume.reason_hint'.tr,
                    icon: Icons.edit_note_rounded),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'my_visits.resume.enter_reason'.tr
                    : null,
              ),
              const SizedBox(height: 18),

              // Date (required)
              _FieldLabel('my_visits.resume.date_label'.tr),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _decoration(context,
                      hint: 'my_visits.resume.date_hint'.tr,
                      icon: Icons.event_rounded),
                  child: Text(
                    _selectedDate == null
                        ? 'my_visits.resume.date_hint'.tr
                        : dateFmt.format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? colors.textSecondary
                          : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.canvas,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                'my_visits.resume.submit'.tr,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context,
      {required String hint, required IconData icon}) {
    final colors = context.appColors;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13.5),
      prefixIcon: Icon(icon, color: colors.textSecondary, size: 20),
      filled: true,
      fillColor: colors.card,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}
