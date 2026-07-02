import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all',
                style: TextStyle(color: Vibe.mint, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
