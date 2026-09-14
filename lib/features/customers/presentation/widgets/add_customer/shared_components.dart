part of '../add_customer_bottom_sheet.dart';

extension SharedComponentsExtension on _AddCustomerBottomSheetState {
  // ===========================================================================
  // Shared field widgets — same look as before, now error-aware
  // ===========================================================================
  Widget _gap([double height = 10]) => SizedBox(height: _spacing(height));

  Widget _twoCol(Widget left, Widget right, {int flexLeft = 1, int flexRight = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: flexLeft, child: left),
        SizedBox(width: _spacing(8)),
        Expanded(flex: flexRight, child: right),
      ],
    );
  }

  Widget _label(String label, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: _fontSize(13),
              fontWeight: FontWeight.w700,
            ),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: _fontSize(13),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
      );

  /// Sub-label under a field. Used where the SAP meaning of a field is not
  /// guessable from its name — a rep cannot be expected to know that
  /// "Search Term 1" is the place and "Search Term 2" is the shop.
  Widget _hint(String msg) => Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(
          msg,
          style: TextStyle(
            color: context.appColors.textSecondary.withValues(alpha: 0.7),
            fontSize: _fontSize(11),
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _errorText(String msg) => Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(
          msg,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: _fontSize(11),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildIconBox(IconData icon, {double size = 32, double iconSize = 18}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _inputCard({
    required Widget child,
    String? label,
    IconData? icon,
    bool required = false,
    bool compact = false,
    String? error,
  }) {
    final hasError = error != null;
    final card = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 14 : context.rw(10),
        vertical: widget.isTablet ? 10 : context.rh(8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? Theme.of(context).colorScheme.error
              : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null || icon != null)
                  Row(
                    children: [
                      if (icon != null) ...[
                        _buildIconBox(icon, size: 24, iconSize: 14),
                        const SizedBox(width: 6),
                      ],
                      if (label != null)
                        Expanded(
                          child: _cardLabel(label, required: required, fontSize: 12),
                        ),
                    ],
                  ),
                if (label != null || icon != null) const SizedBox(height: 5),
                child,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  _buildIconBox(icon, size: 30, iconSize: 16),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (label != null) ...[
                        _cardLabel(label, required: required, fontSize: 13),
                        const SizedBox(height: 4),
                      ],
                      child,
                    ],
                  ),
                ),
              ],
            ),
    );

    if (hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          card,
          _errorText('add_customer.$error'.tr),
        ],
      );
    }
    return card;
  }

  Widget _cardLabel(String label, {bool required = false, double fontSize = 13}) => RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: _fontSize(fontSize),
            fontWeight: FontWeight.w700,
          ),
          children: required
              ? [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: _fontSize(fontSize),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ]
              : null,
        ),
      );

  InputDecoration _decoration(String hint,
      {String? error, bool readOnly = false, Widget? suffixIcon}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c),
        );

    return InputDecoration(
      isDense: true,
      hintText: hint,
      counterText: '',
      hintStyle: TextStyle(
        color: const Color(0xFF94A3B8),
        fontSize: _fontSize(12),
      ),
      filled: true,
      fillColor: readOnly
          ? context.appColors.border.withValues(alpha: 0.2)
          : const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 12 : context.rw(10),
        vertical: widget.isTablet ? 10 : context.rh(7),
      ),
      suffixIcon: suffixIcon,
      enabledBorder: border(
        error != null
            ? Theme.of(context).colorScheme.error
            : const Color(0xFFE2E8F0),
      ),
      focusedBorder: border(Theme.of(context).colorScheme.primary),
      errorBorder: border(Theme.of(context).colorScheme.error),
      focusedErrorBorder: border(Theme.of(context).colorScheme.error),
    );
  }

  Widget _text(
    TextEditingController controller,
    String hint, {
    String? label,
    IconData? icon,
    bool required = false,
    bool compact = false,
    String? error,
    int? maxLength,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onChanged,
  }) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      onChanged: onChanged,
      inputFormatters: maxLength != null
          ? [LengthLimitingTextInputFormatter(maxLength)]
          : null,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: _fontSize(13),
        fontWeight: FontWeight.w500,
      ),
      decoration: _decoration(hint, error: error),
    );

    if (label != null || icon != null) {
      return _inputCard(
        label: label,
        icon: icon,
        required: required,
        compact: compact,
        error: error,
        child: field,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        if (error != null) _errorText('add_customer.$error'.tr),
      ],
    );
  }

  Widget _phone(
    PhoneController controller,
    String hint, {
    String? label,
    IconData? icon,
    bool required = false,
    bool compact = false,
    String? error,
    required ValueChanged<String> onChanged,
  }) {
    final field = PhoneFormField(
      controller: controller,
      onChanged: (p) => onChanged(p.international),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: _fontSize(13),
        fontWeight: FontWeight.w500,
      ),
      countryButtonStyle: CountryButtonStyle(
        showFlag: true,
        showIsoCode: false,
        showDialCode: true,
        showDropdownIcon: true,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        textStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: _fontSize(12),
        ),
      ),
      validator: PhoneValidator.compose([
        PhoneValidator.required(context,
            errorText: 'add_customer.error.required'.tr),
        PhoneValidator.validMobile(context,
            errorText: 'add_customer.error.invalid_phone'.tr),
      ]),
      decoration: _decoration(hint, error: error),
    );

    if (label != null || icon != null) {
      return _inputCard(
        label: label,
        icon: icon,
        required: required,
        compact: compact,
        error: error,
        child: field,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        if (error != null) _errorText('add_customer.$error'.tr),
      ],
    );
  }

  Widget _dropdown({
    required String? value,
    required List<SapOption> options,
    required ValueChanged<String?> onChanged,
    String? label,
    IconData? icon,
    bool required = false,
    bool compact = false,
    String? hint,
    String? error,
    bool isDisabled = false,
    bool showCode = false,
  }) {
    final resolved = [...options];
    final hasValue = value != null && value.isNotEmpty;
    if (hasValue && !resolved.any((o) => o.code == value)) {
      resolved.insert(
        0,
        SapOption(
            value, 'add_customer.unrecognised_code'.trParams({'code': value})),
      );
    }

    final dropdown = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 12 : context.rw(8),
        vertical: widget.isTablet ? 6 : context.rh(3),
      ),
      decoration: BoxDecoration(
        color: isDisabled
            ? context.appColors.border.withValues(alpha: 0.2)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: error != null
              ? Theme.of(context).colorScheme.error
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: hasValue ? value : null,
          isExpanded: true,
          isDense: true,
          hint: Text(
            hint ?? '',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: _fontSize(12),
            ),
          ),
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF64748B),
            size: _fontSize(18),
          ),
          items: isDisabled
              ? null
              : resolved
                  .map((o) => DropdownMenuItem<String>(
                        value: o.code,
                        child: Text(
                          showCode ? o.display : o.labelEn,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: _fontSize(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
          onChanged: isDisabled ? null : onChanged,
        ),
      ),
    );

    if (label != null || icon != null) {
      return _inputCard(
        label: label,
        icon: icon,
        required: required,
        compact: compact,
        error: error,
        child: dropdown,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dropdown,
        if (error != null) _errorText('add_customer.$error'.tr),
      ],
    );
  }

  /// Two-option choices read better as a segmented control than a dropdown.
  Widget _segmented({
    required String? value,
    required List<SapOption> options,
    required ValueChanged<String> onChanged,
    bool compact = false,
  }) {
    return Row(
      children: [
        for (final o in options) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                  vertical: compact ? 6 : context.rh(14),
                ),
                decoration: BoxDecoration(
                  color: value == o.code
                      ? Theme.of(context).colorScheme.secondary
                      : context.appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(compact ? 8 : 12),
                  border: Border.all(color: context.appColors.border),
                ),
                child: Text(
                  o.labelEn,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: value == o.code
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: _fontSize(compact ? 11 : 14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          if (o != options.last) SizedBox(width: compact ? 6 : 8),
        ],
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.rw(12),
          vertical: context.rh(10),
        ),
        decoration: BoxDecoration(
          color: context.appColors.border.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: _fontSize(16),
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _moreToggle({
    required bool expanded,
    required VoidCallback onTap,
    String? labelCollapsed,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: _fontSize(20),
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                expanded
                    ? 'add_customer.show_less'.tr
                    : (labelCollapsed ?? 'add_customer.more_details'.tr),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: _fontSize(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

  /// Moved here from the photos step — it belongs next to Payment Term,
  /// which is the field that actually triggers credit review.
  Widget _creditNotice() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: context.appColors.warningAlt.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.appColors.warningAlt.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined,
                color: context.appColors.warningAlt, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'add_customer.credit_notice'.tr,
                style: TextStyle(
                  color: context.appColors.warningAlt,
                  fontSize: _fontSize(11.5),
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _actionTile({
    required String label,
    required String sub,
    required IconData icon,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isTablet ? 14 : context.rw(10),
          vertical: widget.isTablet ? 10 : context.rh(8),
        ),
        decoration: BoxDecoration(
          color: completed
              ? const Color(0xFFF0FDF4)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: completed
                ? context.appColors.success
                : const Color(0xFFE2E8F0),
            width: completed ? 1.5 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: completed
                    ? context.appColors.success.withValues(alpha: 0.12)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: _fontSize(17),
                  color: completed
                      ? context.appColors.success
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: _fontSize(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: _fontSize(11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.add_a_photo_rounded,
              color: completed
                  ? context.appColors.success
                  : const Color(0xFF94A3B8),
              size: _fontSize(18),
            ),
          ],
        ),
      ),
    );
  }
}
