import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Dialog that makes the rep give a valid reason before a stop can be skipped.
///
/// A preset must be chosen; picking "Other" additionally requires a typed
/// description. Returns the chosen reason string (the preset's label, or the
/// custom text for "Other"), or `null` if the rep cancels — so the caller only
/// skips when it gets a real reason back.
class SkipStopReasonDialog extends StatefulWidget {
  const SkipStopReasonDialog({super.key, required this.stopName});

  final String stopName;

  /// Shows the dialog and resolves to the chosen reason, or `null` on cancel.
  static Future<String?> show(BuildContext context, {required String stopName}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SkipStopReasonDialog(stopName: stopName),
    );
  }

  @override
  State<SkipStopReasonDialog> createState() => _SkipStopReasonDialogState();
}

class _SkipStopReasonDialogState extends State<SkipStopReasonDialog> {
  static const _otherKey = 'other';

  /// Preset reason keys → localization keys. Order is the display order.
  static const _presets = <String, String>{
    'shop_closed': 'my_visits.route_info.reason_shop_closed',
    'customer_unavailable': 'my_visits.route_info.reason_customer_unavailable',
    'no_access': 'my_visits.route_info.reason_no_access',
    'rescheduled': 'my_visits.route_info.reason_rescheduled',
    _otherKey: 'my_visits.route_info.reason_other',
  };

  String? _selected;
  final _otherController = TextEditingController();

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_selected == null) return false;
    if (_selected == _otherKey) return _otherController.text.trim().isNotEmpty;
    return true;
  }

  String? _resolveReason() {
    if (_selected == null) return null;
    if (_selected == _otherKey) {
      final text = _otherController.text.trim();
      return text.isEmpty ? null : text;
    }
    return _presets[_selected]!.tr;
  }

  void _confirm() {
    final reason = _resolveReason();
    if (reason == null) return;
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.skip_next_rounded, color: scheme.error, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'my_visits.route_info.skip_title'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'my_visits.route_info.skip_subtitle'
                  .trParams({'name': widget.stopName}),
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            for (final entry in _presets.entries)
              _ReasonOption(
                label: entry.value.tr,
                selected: _selected == entry.key,
                onTap: () => setState(() => _selected = entry.key),
              ),
            if (_selected == _otherKey) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherController,
                autofocus: true,
                maxLines: 2,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'my_visits.route_info.skip_other_hint'.tr,
                  hintStyle:
                      TextStyle(color: colors.textSecondary, fontSize: 13),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: colors.surfaceSoft,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary, width: 1.4),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'common.cancel'.tr,
            style: TextStyle(
                color: colors.textSecondary, fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isValid ? _confirm : null,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(
            'my_visits.route_info.skip_confirm'.tr,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            disabledBackgroundColor: scheme.error.withValues(alpha: 0.4),
            disabledForegroundColor: scheme.onError,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : colors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? scheme.primary : colors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
