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
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return GlassCard(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 18,
        isTablet ? 20 : 16,
        isTablet ? 18 : 12,
        isTablet ? 12 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'settings.language_title'.tr,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: isTablet ? 18 : 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 4),
          BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              final supported =
                  context.read<LanguageCubit>().supportedLanguages;
              final language = supported.firstWhere(
                (l) => l.code == locale.languageCode,
                orElse: () => supported.first,
              );
              return InkWell(
                onTap: () => showLanguageSelectorSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 14 : 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.translate_rounded,
                        size: isTablet ? 24 : 20,
                        color: scheme.primary,
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Text(
                        'settings.language'.tr,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: isTablet ? 16 : 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        language.flag,
                        style: TextStyle(fontSize: isTablet ? 18 : 14),
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        language.nameKey.tr,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: isTablet ? 15 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: isTablet ? 6 : 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: isTablet ? 24 : 20,
                        color: colors.textSecondary,
                      ),
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