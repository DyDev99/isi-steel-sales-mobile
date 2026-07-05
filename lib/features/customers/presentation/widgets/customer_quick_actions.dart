import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

class CustomerQuickActions extends StatelessWidget {
  const CustomerQuickActions({
    super.key,
    required this.onCall,
    required this.onCreateOpportunity,
    required this.onLogVisit,
    required this.onAddNote,
  });

  final VoidCallback onCall;
  final VoidCallback onCreateOpportunity;
  final VoidCallback onLogVisit;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onCreateOpportunity,
            icon: const Icon(Icons.trending_up_rounded, size: 18, color: Colors.white),
            label: Text('customers.create_opportunity'.tr,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Vibe.violet,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconAction(icon: Icons.call_rounded, label: 'customers.call'.tr, onTap: onCall),
        const SizedBox(width: 8),
        _IconAction(icon: Icons.pin_drop_rounded, label: 'customers.visit'.tr, onTap: onLogVisit),
        const SizedBox(width: 8),
        _IconAction(icon: Icons.note_add_rounded, label: 'customers.note'.tr, onTap: onAddNote),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Vibe.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Vibe.stroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Vibe.violet, size: 18),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Vibe.muted, fontSize: 9.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
