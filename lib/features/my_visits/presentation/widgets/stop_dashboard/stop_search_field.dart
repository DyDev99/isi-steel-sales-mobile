import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Debounced search box for the Stop Dashboard. Emits [onChanged] 300 ms after
/// the last keystroke so filtering doesn't run on every character.
class StopSearchField extends StatefulWidget {
  const StopSearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  State<StopSearchField> createState() => _StopSearchFieldState();
}

class _StopSearchFieldState extends State<StopSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 300), () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: colors.textPrimary, fontSize: 13.sp),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'my_visits.stop_dashboard.search_hint'.tr,
        hintStyle: TextStyle(color: colors.textHint, fontSize: 13.sp),
        prefixIcon:
            Icon(Icons.search_rounded, size: 18.w, color: colors.textSecondary),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 16.w, color: colors.textSecondary),
                onPressed: () {
                  _controller.clear();
                  _debounce?.cancel();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: colors.surfaceSoft,
        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
