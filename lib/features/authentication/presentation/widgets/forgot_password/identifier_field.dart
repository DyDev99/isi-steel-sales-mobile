import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/vibe_field.dart';

/// NOTE ON SETUP
/// `phone_form_field` needs its localization delegate wired up once at the
/// app root (MaterialApp), or the country picker / validator error text
/// will throw a "no MaterialLocalizations found" error:
///
///   MaterialApp(
///     localizationsDelegates: [
///       ...GlobalMaterialLocalizations.delegates,
///       ...PhoneFieldLocalization.delegates,
///     ],
///     supportedLocales: PhoneFieldView.supportedLocales,
///     ...
///   )
///
/// Add that next to the app's existing localization setup if it isn't
/// there already — otherwise the phone tab of this field will crash when
/// it first builds.

/// Which kind of identifier the person is currently entering.
enum ContactMode { email, phone }

/// A single field that toggles between an email input and a
/// `phone_form_field` phone input, styled to match [VibeField].
///
/// The two modes hold fundamentally different value types (a plain string
/// vs a [PhoneNumber]), so this widget is not a [FormField] itself.
/// Instead it exposes [validate] and [value] via [IdentifierFieldState] —
/// give it a `GlobalKey<IdentifierFieldState>` and call
/// `key.currentState!.validate()` alongside the surrounding `Form`'s own
/// `validate()` on submit (see `login_screen.dart` /
/// `forgot_password_screen.dart` for the pattern).
class IdentifierField extends StatefulWidget {
  const IdentifierField({
    super.key,
    this.initialMode = ContactMode.email,
    this.defaultCountry = IsoCode.KH,
    this.required = true,
    this.textInputAction,
    this.onModeChanged,
  });

  final ContactMode initialMode;

  /// Country pre-selected in the phone picker (Cambodia by default).
  final IsoCode defaultCountry;
  final bool required;
  final TextInputAction? textInputAction;
  final ValueChanged<ContactMode>? onModeChanged;

  @override
  State<IdentifierField> createState() => IdentifierFieldState();
}

class IdentifierFieldState extends State<IdentifierField> {
  late ContactMode _mode = widget.initialMode;

  final _emailController = TextEditingController();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<PhoneNumber>>();
  late final PhoneController _phoneController = PhoneController(
    initialValue: PhoneNumber(isoCode: widget.defaultCountry, nsn: ''),
  );

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// The identifier ready to submit: trimmed email, or the phone number as
  /// `+<countryCode><nsn>` (e.g. `+85512345678`). Adjust here if the
  /// backend expects a different phone format.
  String get value {
    if (_mode == ContactMode.email) return _emailController.text.trim();
    final phone = _phoneController.value;
    if (phone.nsn.isEmpty) return '';
    return '+${phone.countryCode}${phone.nsn}';
  }

  ContactMode get mode => _mode;

  /// Validates whichever input is currently active. Call this alongside the
  /// surrounding `Form`'s own `validate()` before submitting.
  bool validate() {
    if (_mode == ContactMode.email) {
      return _emailFieldKey.currentState?.validate() ?? false;
    }
    return _phoneFieldKey.currentState?.validate() ?? false;
  }

  String? _phoneValidator(BuildContext context, PhoneNumber? phone) {
    if (!widget.required && (phone == null || phone.nsn.isEmpty)) return null;
    return PhoneValidator.compose([
      PhoneValidator.required(context),
      PhoneValidator.validMobile(context),
    ])(phone);
  }

  void _switchMode(ContactMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    widget.onModeChanged?.call(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeSwitcher(mode: _mode, onChanged: _switchMode),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _mode == ContactMode.email
              ? _emailField(key: const ValueKey('identifier-email'))
              : _phoneField(
                  key: const ValueKey('identifier-phone'),
                  context: context,
                ),
        ),
      ],
    );
  }

  Widget _emailField({required Key key}) {
    return VibeField(
      key: key,
      formFieldKey: _emailFieldKey,
      controller: _emailController,
      label: 'auth.email'.tr,
      icon: Icons.alternate_email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.email],
      required: widget.required,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return widget.required ? 'auth.email_required'.tr : null;
        }
        return _emailRegExp.hasMatch(v.trim())
            ? null
            : 'auth.invalid_email'.tr;
      },
    );
  }

  Widget _phoneField({required Key key, required BuildContext context}) {
    return PhoneFormField(
      key: _phoneFieldKey,
      controller: _phoneController,
      textInputAction: widget.textInputAction,
      style: const TextStyle(color: Vibe.text, fontSize: 15),
      cursorColor: Vibe.pink,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      countrySelectorNavigator: const CountrySelectorNavigator.bottomSheet(),
      isCountrySelectionEnabled: true,
      isCountryButtonPersistent: true,
      autofillHints: const [AutofillHints.telephoneNumber],
      countryButtonStyle: const CountryButtonStyle(
        showDialCode: true,
        showIsoCode: false,
        showFlag: true,
        flagSize: 16,
        textStyle: TextStyle(color: Vibe.text, fontSize: 15),
      ),
      decoration: vibeFieldDecoration(
        label: 'auth.phone_number'.tr,
        required: widget.required,
      ),
      validator: (phone) => _phoneValidator(context, phone),
    );
  }
}

/// Small segmented pill that toggles between Email and Phone, styled to
/// match the rest of the Vibe auth screens.
class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.mode, required this.onChanged});

  final ContactMode mode;
  final ValueChanged<ContactMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Vibe.surfaceStrong,
        borderRadius: BorderRadius.circular(Vibe.radius),
        border: Border.all(color: Vibe.stroke),
      ),
      child: Row(
        children: [
          _segment(
            label: 'auth.email'.tr,
            icon: Icons.alternate_email,
            selected: mode == ContactMode.email,
            onTap: () => onChanged(ContactMode.email),
          ),
          _segment(
            label: 'auth.phone_number'.tr,
            icon: Icons.phone_outlined,
            selected: mode == ContactMode.phone,
            onTap: () => onChanged(ContactMode.phone),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Vibe.pink.withValues(alpha: 0.14) : null,
            borderRadius: BorderRadius.circular(Vibe.radius - 2),
            border: selected
                ? Border.all(color: Vibe.pink.withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Vibe.pink : Vibe.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Vibe.pink : Vibe.muted,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}