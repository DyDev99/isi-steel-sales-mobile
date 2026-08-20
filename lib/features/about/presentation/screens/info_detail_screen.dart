import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
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
            fontSize: context.rsp(17),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          // Policy pages are long prose, and prose has an optimal measure:
          // past roughly 75 characters a line the eye loses its place on the
          // return sweep. On a tablet an unconstrained column runs to twice
          // that, which is why the page felt hard to read rather than merely
          // wide. 680 keeps the measure sane and centres the remainder.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Scaled with the type rather than held fixed. The constraint
              // that matters is the *measure* — characters per line, not
              // pixels — so a 1.5x larger font needs a proportionally wider
              // column to keep the same comfortable ~75-character line.
              // Holding 680 while the text grew would have squeezed the prose
              // into a narrow strip instead of improving it.
              maxWidth: context.responsive(
                compact: double.infinity,
                medium: 880.0,
                expanded: 960.0,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  context.pagePadding, 8, context.pagePadding, 32),
              children: [
                if (_hasSecurityCallout) ...[
                  _Callout(
                    title: 'about.stay_secure_title'.tr,
                    body: 'about.stay_secure_body'.tr,
                    color: scheme.primary,
                  ),
                  SizedBox(height: context.rh(20)),
                ],
                for (final section in topic.sections) ...[
                  _Section(topic: topic, section: section),
                  SizedBox(height: context.rh(22)),
                ],
                SizedBox(height: context.rh(4)),
                Center(
                  child: Text(
                    '${'about.last_updated'.tr} · 19 Aug 2026',
                    style: TextStyle(
                      color: colors.textHint,
                      fontSize: context.rsp(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            fontSize: context.rsp(16),
            fontWeight: FontWeight.w800,
            height: context.rh(1.3),
          ),
        ),
        SizedBox(height: context.rh(10)),
        for (var i = 1; i <= section.bulletCount; i++)
          Padding(
            padding: EdgeInsets.only(bottom: single ? 0 : context.rh(9)),
            child: single
                // A section with one entry is prose, not a list: a solitary
                // bullet reads as a formatting error rather than as emphasis.
                ? Text(
                    topic.bulletKey(section, i).tr,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.rsp(14.5),
                      height: context.rh(1.6),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        // Nudged down to sit on the first line's baseline
                        // rather than its ascender.
                        margin: EdgeInsets.only(
                            top: context.rh(8), right: context.rw(10)),
                        width: context.rw(5),
                        height: context.rh(5),
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
                            fontSize: context.rsp(14.5),
                            height: context.rh(1.55),
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
      padding: EdgeInsets.all(context.rr(16)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: color, size: context.rr(20)),
          SizedBox(width: context.rw(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: context.rh(5)),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(13.5),
                    height: context.rh(1.5),
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
