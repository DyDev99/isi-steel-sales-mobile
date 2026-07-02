import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.name, this.onProfileTap, this.onBellTap});

  final String name;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBellTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good to see you 👋',
                  style: TextStyle(color: Vibe.muted, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                    color: Vibe.text, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        _IconBubble(icon: Icons.notifications_none_rounded, onTap: onBellTap),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: Vibe.cta,
              borderRadius: BorderRadius.circular(14),
            ),
            child: GestureDetector(
  onTap: onProfileTap,
  child: Container(
    width: 44.w, // Using screenutil
    height: 44.h,
    decoration: BoxDecoration(
      gradient: Vibe.cta,
      borderRadius: BorderRadius.circular(22.r), // Makes it a perfect circle
      // Add the image here
      image: const DecorationImage(
        image: NetworkImage('https://png.pngtree.com/png-clipart/20240111/original/pngtree-cool-smile-profile-emoji-png-image_14087472.png'), 
        fit: BoxFit.cover,
      ),
    ),
    
  ),
),
          ),
        ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Vibe.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Vibe.stroke),
        ),
        child: const Icon(Icons.notifications_none_rounded,
            color: Vibe.text, size: 22),
      ),
    );
  }
}
