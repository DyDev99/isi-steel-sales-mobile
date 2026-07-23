import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/bloc/language_cubit.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/widgets/language_selector_sheet.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';

/// "Language" block for the Profile screen — a single row showing the active
/// language (flag + native name) that opens [showLanguageSelectorSheet].
/// Mirrors [AppearanceSection]'s layout so Profile settings read as one family.
class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'settings.language_title'.tr,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              final supported = context.read<LanguageCubit>().supportedLanguages;
              final language = supported.firstWhere(
                (l) => l.code == locale.languageCode,
                orElse: () => supported.first,
              );
              return InkWell(
                onTap: () => showLanguageSelectorSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.translate_rounded,
                          size: 20, color: scheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'settings.language'.tr,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(language.flag, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        language.nameKey.tr,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 20, color: colors.textSecondary),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
