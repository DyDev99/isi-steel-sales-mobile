import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

class NavTab {
  const NavTab(this.icon, this.label);
  final IconData icon;
  final String label;
}

class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Custom Painted Background Bar that adapts to the selected index
            CustomPaint(
              size: Size(double.infinity, 66.h),
              painter: NotchBarPainter(
                currentIndex: currentIndex,
                totalTabs: tabs.length,
              ),
            ),
            
            // Interactive Item Layer
            SizedBox(
              height: 66.h,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: i == currentIndex
                          ? _SelectedFabItem(
                              tab: tabs[i],
                              onTap: () => onTap(i),
                            )
                          : _SideNavItem(
                              tab: tabs[i],
                              selected: false,
                              onTap: () => onTap(i),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Side Navigation Item (Unselected State)
class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            tab.icon,
            size: 24.r,
            color: selected ? const Color(0xFF2E7D32) : Vibe.muted,
          ),
          SizedBox(height: 4.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 5.r,
            width: selected ? 5.r : 0,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamically elevated active tab sitting inside the moving notch scoop
class _SelectedFabItem extends StatelessWidget {
  const _SelectedFabItem({
    required this.tab,
    required this.onTap,
  });

  final NavTab tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -14.h), // Elevates the selected button up into the scoop space
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52.r,
              height: 52.r,
              decoration: BoxDecoration(
                gradient: Vibe.cta,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                tab.icon,
                size: 24.r,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              height: 5.r,
              width: 5.r,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter drawing the curved layout profile matching the active tab position
class NotchBarPainter extends CustomPainter {
  NotchBarPainter({required this.currentIndex, required this.totalTabs});

  final int currentIndex;
  final int totalTabs;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Vibe.surface
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Vibe.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final radius = 24.r;
    
    // Dynamic calculation of the notch center alignment based on active tab
    final double tabWidth = size.width / totalTabs;
    final double cx = (tabWidth * currentIndex) + (tabWidth / 2);
    
    final notchRadius = 36.r; // Controlled depth of center curve

    final path = Path()
      ..moveTo(radius, 0)
      // Left side edge up to the dynamic notch start
      ..lineTo(cx - notchRadius - 10.w, 0)
      // Smooth continuous bezier curve into the center dip
      ..cubicTo(
        cx - notchRadius + 4.w, 0,
        cx - notchRadius + 6.w, notchRadius,
        cx, notchRadius,
      )
      // Smooth continuous bezier curve back out of the center dip
      ..cubicTo(
        cx + notchRadius - 6.w, notchRadius,
        cx + notchRadius - 4.w, 0,
        cx + notchRadius + 10.w, 0,
      )
      // Right side edge
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius))
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height), radius: Radius.circular(radius))
      ..lineTo(radius, size.height)
      ..arcToPoint(Offset(0, size.height - radius), radius: Radius.circular(radius))
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..close();

    // Draw Drop Shadow matching original configuration
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Draw Main Bar Background fill and border stroke
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant NotchBarPainter oldDelegate) {
    // Repaint only if the index or layout configuration parameters change
    return oldDelegate.currentIndex != currentIndex || oldDelegate.totalTabs != totalTabs;
  }
}