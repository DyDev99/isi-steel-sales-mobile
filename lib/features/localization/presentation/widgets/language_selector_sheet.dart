import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/localization/domain/entities/language_entity.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/bloc/language_cubit.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/widgets/language_reload_dialog.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

/// Opens the language picker. Tapping a language applies it **instantly**
/// (every `.tr` in the live tree re-resolves — no restart), persists it, and
/// closes the sheet after a short beat so the user sees the switch land in
/// their new language. The [LanguageCubit] is read from an ancestor provider,
/// so this works from anywhere below `MaterialApp`.
Future<void> showLanguageSelectorSheet(BuildContext context) {
  final languageCubit = context.read<LanguageCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: languageCubit,
      child: const _LanguageSelectorSheet(),
    ),
  );
}

class _LanguageSelectorSheet extends StatefulWidget {
  const _LanguageSelectorSheet();

  @override
  State<_LanguageSelectorSheet> createState() => _LanguageSelectorSheetState();
}

class _LanguageSelectorSheetState extends State<_LanguageSelectorSheet> {
  /// Code currently being applied, for the per-tile progress spinner.
  String? _switching;

  Future<void> _select(String code) async {
    if (_switching != null) return;
    final cubit = context.read<LanguageCubit>();
    if (cubit.state.languageCode == code) {
      Navigator.of(context).pop();
      return;
    }

    // Ask before switching: applying a language reloads the whole app
    // (MaterialApp is recreated) so every screen re-renders in the new
    // language — the user opts into that, it never happens under them.
    final target = cubit.supportedLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => cubit.supportedLanguages.first,
    );
    final confirmed = await showLanguageReloadConfirmDialog(context, target);
    if (!confirmed || !mounted) return;

    setState(() => _switching = code);
    await cubit.changeLanguage(code);

    // The reload the dialog promised. Recreating MaterialApp alone is not
    // enough: the shared global [navigatorKey] makes Flutter *reparent* the
    // existing Navigator (stack, screen state and all) into the new tree
    // instead of rebuilding it. Resetting the stack to the shell guarantees
    // every screen — and the data it loads — comes back in the new language.
    // This also dismisses this sheet (it is a route on the same stack).
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(Static.main, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // LocalizedBuilder so the sheet itself re-renders live mid-switch.
    return LocalizedBuilder(
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'language.choose_title'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'language.choose_subtitle'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<LanguageCubit, Locale>(
                builder: (context, locale) => Column(
                  children: [
                    for (final language
                        in context.read<LanguageCubit>().supportedLanguages)
                      LanguageOptionTile(
                        language: language,
                        selected: locale.languageCode == language.code,
                        switching: _switching == language.code,
                        onTap: () => _select(language.code),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable language row: flag, native name, region line, animated
/// radio that morphs into a progress spinner while that language loads.
class LanguageOptionTile extends StatelessWidget {
  const LanguageOptionTile({
    super.key,
    required this.language,
    required this.selected,
    required this.onTap,
    this.switching = false,
  });

  final LanguageEntity language;
  final bool selected;
  final bool switching;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Material(
          color: selected
              ? scheme.primary.withValues(alpha: 0.10)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(13),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.16)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(language.flag,
                        style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // Native name — always in its own language.
                          language.nameKey.tr,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          language.regionKey.tr,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  switching
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        )
                      : Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected ? scheme.primary : scheme.outline,
                          size: 22,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
