import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/guest/guest_cta_card.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/guest/guest_fade_in.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/guest/guest_my_work_grid.dart';

/// The guest (signed-out) home experience.
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
      padding: EdgeInsets.fromLTRB(
        0,
        topInset + 8,
        0,
        context.deviceInsets.scrollBottomInset(extra: 16),
      ),
      children: [
        const SizedBox(height: 36),
        GuestFadeIn(
          delay: Duration.zero,
          child: Padding(
            padding: EdgeInsets.all(context.pagePadding),
            child: GuestCtaCard(onAuthenticate: onLogin),
          ),
        ),
        const SizedBox(height: 8),
        GuestFadeIn(
          delay: _step,
          child: GuestMyWorkGrid(onRequireLogin: onLogin),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
