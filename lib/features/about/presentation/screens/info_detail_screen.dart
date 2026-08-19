import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/about/domain/info_topic.dart';

/// The detail page behind every card on the About hub.
///
/// One screen serves all five topics rather than five near-identical screens.
/// Privacy, Terms, Security, Support and About are the same shape — a stack of
/// headed sections — and five copies of that shape is five places for the
/// padding, the type scale and the dark-mode colours to drift apart.
class InfoDetailScreen extends StatelessWidget {
  const InfoDetailScreen({super.key, required this.topic});

  final InfoTopic topic;

  /// Security guidance carries a highlighted warning; nothing else does.
  bool get _hasSecurityCallout => topic.id == 'security';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          topic.titleKey.tr,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (_hasSecurityCallout) ...[
              _Callout(
                title: 'about.stay_secure_title'.tr,
                body: 'about.stay_secure_body'.tr,
                color: scheme.primary,
              ),
              const SizedBox(height: 20),
            ],
            for (final section in topic.sections) ...[
              _Section(topic: topic, section: section),
              const SizedBox(height: 22),
            ],
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${'about.last_updated'.tr} · 19 Aug 2026',
                style: TextStyle(
                  color: colors.textHint,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.topic, required this.section});

  final InfoTopic topic;
  final InfoSection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final single = section.bulletCount == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          topic.sectionTitleKey(section).tr,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 1; i <= section.bulletCount; i++)
          Padding(
            padding: EdgeInsets.only(bottom: single ? 0 : 9),
            child: single
                // A section with one entry is prose, not a list: a solitary
                // bullet reads as a formatting error rather than as emphasis.
                ? Text(
                    topic.bulletKey(section, i).tr,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        // Nudged down to sit on the first line's baseline
                        // rather than its ascender.
                        margin: const EdgeInsets.only(top: 8, right: 10),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          topic.bulletKey(section, i).tr,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14.5,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title, body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
