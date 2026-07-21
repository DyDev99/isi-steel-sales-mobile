import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/guest/guest_cta_card.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/guest/guest_fade_in.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/guest/guest_my_work_grid.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/guest/guest_quick_action_grid.dart';

/// The guest (signed-out) home experience.
///
/// Each section is its own small, theme-aware widget; this screen only composes
/// and spaces them, so it stays well under the 250-line ceiling. Sections fade
/// and rise in with a short stagger (see [GuestFadeIn]) for a premium reveal.
///
/// Every locked affordance routes to [onLogin] — the shell wires that to the
/// shared `AuthGuard`, so there are no dead ends and this widget stays
/// presentation-only.
class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key, required this.onLogin, this.topInset = 0});

  /// Opens the shared login / register prompt.
  final VoidCallback onLogin;

  /// Space reserved at the top for the shell's floating app bar.
  final double topInset;

  /// Stagger step between sections.
  static const _step = Duration(milliseconds: 90);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      // scrollBottomInset keeps the last section clear of the gesture bar /
      // home indicator — the case DeviceInsets centralises.
      padding: EdgeInsets.fromLTRB(
        0,
        topInset + 8,
        0,
        context.deviceInsets.scrollBottomInset(extra: 16),
      ),
      children: [
        GuestFadeIn(
          delay: _step * 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GuestCtaCard(onAuthenticate: onLogin),
          ),
        ),
        const SizedBox(height: 20),
        GuestFadeIn(
          delay: _step,
          child: GuestQuickActionsSection(onRequireLogin: onLogin),
        ),
        const SizedBox(height: 12),
        GuestFadeIn(
          delay: _step * 2,
          child: GuestMyWorkGrid(onRequireLogin: onLogin),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
