import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_cubit.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// A calm, always-visible-when-offline banner styled with gold accent framing,
/// dual-bordered icon avatar, and subtle corner watermarks.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  static const Color _goldBorderColor = Color(0xFFCBA135);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) {
        if (status == ConnectivityStatus.online) return const SizedBox.shrink();
        final colors = context.appColors;

        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _goldBorderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.r),
            child: Stack(
              children: [
                // Top-Left Corner Decorative Circle Watermark
                Positioned(
                  top: -20.r,
                  left: -20.r,
                  child: Container(
                    width: 50.r,
                    height: 50.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.slate.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Bottom-Right Corner Decorative Circle Watermark
                Positioned(
                  bottom: -20.r,
                  right: -20.r,
                  child: Container(
                    width: 50.r,
                    height: 50.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.slate.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Main Banner Content
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  child: Row(
                    children: [
                      // Dual-Bordered Circular Icon Badge
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.slate.withValues(alpha: 0.12),
                          border: Border.all(
                            color: _goldBorderColor.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          color: colors.slate,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'sync.offline_banner'.tr,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
