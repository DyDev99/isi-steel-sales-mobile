import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/animations/app_animations.dart';
import 'package:isi_steel_sales_mobile/core/animations/press_scale.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/about/domain/info_topic.dart';
import 'package:isi_steel_sales_mobile/features/about/presentation/screens/info_detail_screen.dart';

/// The About & Information centre, reached by tapping the SteelForce logo.
///
/// Deliberately not a settings screen: every row here navigates to something
/// to *read*, and none of them changes state. That is why there are no
/// switches, no trailing values and no grouped-inset list — those are the
/// vocabulary of settings, and borrowing them would invite users to expect
/// controls that do not exist.
class AboutHubScreen extends StatelessWidget {
  const AboutHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: colors.textPrimary),
        centerTitle: true,
        title: Text(
          'about.title'.tr,
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const _BrandHeader(),
            const SizedBox(height: 24),
            for (final topic in kInfoTopics) ...[
              _TopicCard(topic: topic),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

/// Logo, product name and what the product is.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        // The "metallic" accent, kept to a whisper: a cool wash across the
        // card rather than a literal chrome gradient, which at phone size
        // reads as a gradient bug rather than as steel.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors.card, scheme.primary, 0.06)!,
            colors.card,
            Color.lerp(colors.card, colors.slate, 0.04)!,
          ],
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/icons/steelforce_splash.png',
            height: 54,
            fit: BoxFit.contain,
            // The brand mark is decorative here — the product name is stated
            // in text directly below, so announcing it twice adds noise.
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => Icon(
              Icons.apartment_rounded,
              size: 40,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'about.subtitle'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${'about.version_label'.tr} $kAppVersion',
              style: TextStyle(
                color: scheme.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final InfoTopic topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return PressScale(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: AppDurations.page,
          reverseTransitionDuration: AppDurations.page,
          pageBuilder: (_, __, ___) => InfoDetailScreen(topic: topic),
          // Slide in from the trailing edge — the platform idiom for moving
          // deeper into a hierarchy, and it reverses correctly on back.
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppCurves.emphasized,
            )),
            child: child,
          ),
        ),
      ),
      child: Semantics(
        button: true,
        label: topic.titleKey.tr,
        hint: topic.descKey.tr,
        child: Container(
          // 76px tall at minimum — comfortably past the 48dp floor for a row
          // people tap while walking a warehouse.
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(topic.icon, size: 20, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      topic.titleKey.tr,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.descKey.tr,
                      // Two lines, then ellipsis: Khmer runs longer than
                      // English for the same sentence, and an unbounded
                      // subtitle would make the cards different heights
                      // depending on the language.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: colors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          'SteelForce',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Version $kAppVersion',
          style: TextStyle(color: colors.textHint, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'about.copyright'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textHint, fontSize: 11.5),
        ),
      ],
    );
  }
}
