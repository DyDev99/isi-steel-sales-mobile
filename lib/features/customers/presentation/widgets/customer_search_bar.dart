import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

class CustomerSearchBar extends StatefulWidget {
  const CustomerSearchBar({
    super.key,
    required this.query,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.hasActiveFilters,
    required this.onAddTap, // 1. Added the required callback parameter
  });

  final String query;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;
  final VoidCallback onAddTap; // 2. Declared the parameter

  @override
  State<CustomerSearchBar> createState() => _CustomerSearchBarState();
}

class _CustomerSearchBarState extends State<CustomerSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant CustomerSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && _controller.text != widget.query) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors; //[cite: 3]
    return Row(
      children: [
        Expanded(
          child: Container(
            height: context.rh(44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.card, //[cite: 3]
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border), //[cite: 3]
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: colors.textSecondary,
                    size: context.rr(20)), //[cite: 3]
                SizedBox(width: context.rw(8)),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: widget.onSearchChanged, //[cite: 3]
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: context.rsp(13.5)), //[cite: 3]
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'customers.search_hint'.tr, //[cite: 3]
                      hintStyle: TextStyle(
                          color: colors.textSecondary,
                          fontSize: context.rsp(13.5)), //[cite: 3]
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.rw(10)),
        InkWell(
          onTap: widget.onFilterTap, //[cite: 3]
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: context.rh(44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.hasActiveFilters
                  ? scheme.primary.withValues(alpha: 0.18) //[cite: 3]
                  : colors.card, //[cite: 3]
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: widget.hasActiveFilters
                      ? scheme.primary
                      : colors.border), //[cite: 3]
            ),
            child: Icon(Icons.tune_rounded,
                color: widget.hasActiveFilters
                    ? scheme.primary
                    : colors.textPrimary, //[cite: 3]
                size: context.rr(20)),
          ),
        ),
        SizedBox(width: context.rw(10)), // Space between filter and add button

        // 3. New Add Customer Button on the right of filter
        InkWell(
          onTap: widget.onAddTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: context.rh(44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: colors.textPrimary,
              size: context.rr(20),
            ),
          ),
        ),
      ],
    );
  }
}
