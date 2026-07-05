import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/verion.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/bloc/language_cubit.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/gradient_button.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

/// Shown once, right after splash. Lets the user pick a display language
/// before they ever see the login form. Same visual language as
/// [LoginScreen] (aurora + glass card + gradient CTA) so the app feels
/// consistent from the very first screen.
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageOption {
  const _LanguageOption(this.code, this.nameKey, this.regionKey, this.flag);
  final String code;
  final String nameKey;
  final String regionKey;
  final String flag;

  /// The language's own name, e.g. "English" or "ភាសាខ្មែរ" — always shown
  /// in that language regardless of which locale is currently active, so
  /// people can find their language even if the UI is showing the wrong one.
  String get name => nameKey.tr;
  String get region => regionKey.tr;
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  static const _options = [
    _LanguageOption('en', 'language.english', 'language.english_region', '🇺🇸'),
    _LanguageOption('kh', 'language.khmer', 'language.khmer_region', '🇰🇭'),
  ];

  late String _selected = 'en';
  bool _saving = false;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    // The English tile is highlighted by default, but LanguageCubit may
    // still be holding whatever locale was saved from a previous session
    // (e.g. Khmer). Without this, the checkmark says "English" while the
    // title, subtitle, and tile labels on this very screen keep rendering
    // in the old language. Force the two back in sync on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectLanguage('en');
    });
  }

  Future<void> _selectLanguage(String code) async {
    if (code == _selected && LocalizationService.instance.currentLanguageCode == code) {
      return;
    }
    setState(() {
      _selected = code;
      _switching = true;
    });
    // Applies immediately — LocalizationService notifies every LocalizedBuilder
    // in the live tree, so text on this very screen (and everywhere else)
    // updates in real time as soon as a tile is tapped, no need to wait for
    // "Let's go".
    await context.read<LanguageCubit>().changeLanguage(code);
    if (!mounted) return;
    setState(() => _switching = false);
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    // Language was already applied the moment the tile was tapped, so this
    // just decides where to land.
    if (!mounted) return;

    // AuthCheckRequested (fired on app boot) has almost certainly resolved
    // by now, so read the latest state directly rather than hard-coding
    // login — an already-signed-in user should land on the main shell, not
    // be sent back through login.
    final authState = context.read<AuthBloc>().state;
    final destination = authState is AuthenticatedState ? Static.main : Static.login;
    Navigator.of(context).pushNamedAndRemoveUntil(destination, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/logos/isi_app_logo.png',
                                width: 160,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'language.choose_title'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Vibe.text,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'language.choose_subtitle'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Vibe.muted, fontSize: 15),
                            ),
                            const SizedBox(height: 28),
                            GlassCard(
                              child: Column(
                                children: [
                                  for (var i = 0; i < _options.length; i++) ...[
                                    if (i != 0) const SizedBox(height: 12),
                                    _LanguageTile(
                                      option: _options[i],
                                      selected: _selected == _options[i].code,
                                      switching: _switching &&
                                          _selected == _options[i].code,
                                      onTap: () =>
                                          _selectLanguage(_options[i].code),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            GradientButton(
                              label: 'auth.lets_go'.tr,
                              loading: _saving,
                              onPressed: _continue,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'language.language_change_anytime'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Vibe.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const VersionFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.selected,
    required this.onTap,
    this.switching = false,
  });

  final _LanguageOption option;
  final bool selected;
  final bool switching;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? Vibe.pink.withValues(alpha: 0.10) : Vibe.surfaceStrong,
        borderRadius: BorderRadius.circular(Vibe.radius),
        border: Border.all(
          color: selected ? Vibe.pink : Vibe.stroke,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Vibe.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Vibe.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: Vibe.stroke),
                  ),
                  child: Text(option.flag, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: TextStyle(
                          color: Vibe.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        option.region,
                        style: TextStyle(color: Vibe.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Vibe.pink : Colors.transparent,
                    border: Border.all(
                      color: selected ? Vibe.pink : Vibe.stroke,
                      width: 1.6,
                    ),
                  ),
                  child: selected
                      ? (switching
                          ? const Padding(
                              padding: EdgeInsets.all(4),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check, size: 16, color: Colors.white))
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}