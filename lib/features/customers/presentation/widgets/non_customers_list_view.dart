import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasources/non_customer_demo_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_audience_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/non_customer_card.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/non_customer_register_screen.dart';

/// The non-customers list, rendered entirely from static demo data.
///
/// **Reads from a const list, not a BLoC.** There is no repository, no use case
/// and no sync behind this — deliberately, because the screen exists to show
/// what the feature would look like before anyone commits to a schema for it.
/// Wiring it to a BLoC now would mean designing the persistence around a shape
/// that is still being argued about.
///
/// It carries its own copy of [CustomerAudienceFilter] so the switch back to
/// customers stays reachable, and scrolls with the list rather than pinning to
/// the top: on a short list there is nothing to scroll, and on a long one a
/// fixed header costs a row of results on every phone in the field.
class NonCustomersListView extends StatelessWidget {
  const NonCustomersListView({
    super.key,
    required this.audience,
    required this.onAudienceChanged,
    required this.customerCount,
  });

  final CustomerAudience audience;
  final ValueChanged<CustomerAudience> onAudienceChanged;
  final int customerCount;

  Future<void> _openRegister(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        settings: const RouteSettings(
          name: NonCustomerRegisterScreen.routeName,
        ),
        builder: (_) => const NonCustomerRegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.rw(16),
              context.rh(26),
              context.rw(16),
              context.rh(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.rh(20)),
                CustomerAudienceFilter(
                  selected: audience,
                  onChanged: onAudienceChanged,
                  customerCount: customerCount,
                  nonCustomerCount: demoNonCustomers.length,
                ),
                SizedBox(height: context.rh(14)),
                _AddNonCustomerButton(onTap: () => _openRegister(context)),
                SizedBox(height: context.rh(14)),

                // Says what this list is for, once. A rep who has only ever
                // seen the customer list will otherwise reasonably assume these
                // are customers whose registration failed.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: context.rr(14),
                      color: colors.textSecondary,
                    ),
                    SizedBox(width: context.rw(6)),
                    Expanded(
                      child: Text(
                        'Parties who buy ISI steel without their own SAP '
                        'account. Each one is linked to the customer it buys '
                        'through.',
                        style: TextStyle(
                          fontSize: context.rsp(11.5),
                          height: 1.4,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            context.rw(16),
            0,
            context.rw(16),
            context.rh(24),
          ),
          sliver: SliverList.separated(
            itemCount: demoNonCustomers.length,
            separatorBuilder: (_, __) => SizedBox(height: context.rh(10)),
            itemBuilder: (context, index) {
              final nonCustomer = demoNonCustomers[index];
              return NonCustomerCard(
                key: ValueKey(nonCustomer.id),
                nonCustomer: nonCustomer,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo only — no detail screen yet.'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddNonCustomerButton extends StatelessWidget {
  const _AddNonCustomerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.add_rounded, size: context.rr(18)),
        label: Text(
          'Register non customer',
          style: TextStyle(
            fontSize: context.rsp(13.5),
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: context.rh(13)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
