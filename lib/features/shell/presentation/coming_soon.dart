import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.emoji});
  final String title;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: TextStyle(fontSize: 48.sp)),
                  SizedBox(height: 12.h),
                  Text(title,
                      style: TextStyle(
                          color: Vibe.text,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 6.h),
                  Text('Coming soon',
                      style: TextStyle(color: Vibe.muted, fontSize: 14.sp)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}