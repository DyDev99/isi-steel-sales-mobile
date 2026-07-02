import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/coming_soon.dart';

class OpportunityScreen extends StatelessWidget {
  const OpportunityScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ComingSoon(title: 'Opportunities', emoji: '📈');
}
