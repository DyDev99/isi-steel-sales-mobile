import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/presentation/cubit/theme_cubit.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/presentation/cubit/theme_state.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/presentation/widgets/theme_option_meta.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/presentation/widgets/theme_selector_sheet.dart';

/// "Appearance" block for the Profile screen — a single **Theme** row that opens
/// the [showThemeSelectorSheet] picker and reflects the active selection live
/// via [ThemeCubit].
///
/// Styled with the same [GlassCard] as [ProfileInfoSection] and fully
/// theme-aware, so it renders correctly in both light and dark. The theme it
/// controls, of course, applies app-wide instantly.
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

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
            'appearance.title'.tr,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              final mode = state.mode;
              return InkWell(
                onTap: () => showThemeSelectorSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(mode.icon, size: 20, color: scheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'appearance.theme'.tr,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        mode.labelKey.tr,
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
