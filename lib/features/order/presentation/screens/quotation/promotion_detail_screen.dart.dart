import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

class PromotionDetailScreen extends StatelessWidget {
  final String categoryTitle;

  const PromotionDetailScreen({
    super.key,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryTitle,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: context.rsp(17),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left_rounded,
            color: colorScheme.primary,
            size: context.rsp(28),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(context.rw(16)),
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(height: context.rh(12)),
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.all(context.rw(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Promotion #${index + 1}',
                      style: TextStyle(
                        fontSize: context.rsp(15),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rw(8),
                        vertical: context.rh(4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          fontSize: context.rsp(11),
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rh(8)),
                Text(
                  'Applicable discount for outlet purchases under category constraints.',
                  style: TextStyle(
                    fontSize: context.rsp(13),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: context.rh(12)),
                const Divider(),
                SizedBox(height: context.rh(8)),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey.shade600),
                    SizedBox(width: context.rw(6)),
                    Text(
                      'Valid: 01 Jun – 31 Aug 2025',
                      style: TextStyle(
                        fontSize: context.rsp(12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}