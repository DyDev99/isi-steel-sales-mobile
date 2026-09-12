import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Quick-action row for guests. Every card is a locked affordance: tapping any
/// of them calls [onRequireLogin] rather than performing the action.
///
/// **No `CoachKeys` here, deliberately.** The authenticated dashboard tags its
/// real quick-action cards with static `CoachKeys` GlobalKeys for the onboarding
/// spotlight.
class GuestQuickActionsSection extends StatelessWidget {
  const GuestQuickActionsSection({super.key, required this.onRequireLogin});

  /// Triggered whenever a guest taps an action that requires an account.
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.pagePadding,
        vertical: context.rh(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionHeader('shell.quick_actions'.tr, letterSpacing: 1.6),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.assignment_outlined,
                  tint: const Color(0xFF22C3D6),
                  label: 'shell.new_quote'.tr,
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: context.rw(8)),
              Expanded(
                child: _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  tint: context.appColors.success,
                  label: 'shell.new_lead'.tr,
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: context.rw(8)),
              Expanded(
                child: _ActionCard(
                  icon: Icons.inventory_2_outlined,
                  tint: const Color(0xFFF5A623),
                  label: 'shell.depot_stock'.tr,
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: context.rw(8)),
              Expanded(
                child: _ActionCard(
                  icon: Icons.person_add_alt_1_outlined,
                  tint: const Color(0xFFEC3F72),
                  label: 'shell.add_customer'.tr,
                  onTap: onRequireLogin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single locked action tile with 3D tactile press and traditional golden accent frame.
class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isPressed = false;

  static const Color _goldLight = Color(0xFFF3E5AB);
  static const Color _goldPrimary = Color(0xFFD4AF37);
  static const Color _goldDark = Color(0xFF996515);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final depthOffset = _isPressed ? 1.5 : 4.0;

    return Semantics(
      button: true,
      label: 'shell.login_required_label'.trParams({'feature': widget.label}),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isPressed ? 2.5 : 0.0, 0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: widget.tint.withValues(alpha: isDark ? 0.25 : 0.15),
                  offset: Offset(0, depthOffset),
                  blurRadius: _isPressed ? 2 : 5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  offset: Offset(0, depthOffset + 1),
                  blurRadius: _isPressed ? 3 : 8,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _goldLight.withValues(alpha: 0.7),
                    _goldPrimary,
                    _goldDark,
                  ],
                ),
              ),
              padding: EdgeInsets.all(1.5.r),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: context.rh(12),
                  horizontal: context.rw(4),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.5.r),
                  color: scheme.surface,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surface,
                      Color.lerp(
                        scheme.surface,
                        widget.tint,
                        0.04,
                      )!,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: context.rr(38),
                      height: context.rr(38),
                      decoration: BoxDecoration(
                        color: widget.tint.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.tint.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          color: widget.tint,
                          size: context.rr(19),
                        ),
                      ),
                    ),
                    SizedBox(height: context.rh(8)),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: context.rsp(11),
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.letterSpacing = 1.6});

  final String text;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8) ??
        theme.colorScheme.onSurface.withValues(alpha: 0.8);

    final double headerBase = context.responsive(compact: 14.0, medium: 16.0);

    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: context.rh(12)),
      child: Row(
        children: [
          Container(
            width: context.rw(4),
            height: context.rh(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.r),
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFF996515)],
              ),
            ),
          ),
          SizedBox(width: context.rw(8)),
          Text(
            text,
            style: TextStyle(
              fontSize: context.rsp(headerBase),
              fontWeight: FontWeight.w900,
              letterSpacing: letterSpacing,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
