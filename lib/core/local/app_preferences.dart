import 'package:hive_flutter/hive_flutter.dart';

/// Non-sensitive app settings. Interface unchanged from the shared_preferences
/// version, so `app.dart` needs no edits — only the backing store swapped to
/// Hive. Hive stores bool/String natively (no JSON), so reads are fast.
abstract interface class AppPreferences {
  bool get isOnboardingComplete;
  Future<void> setOnboardingComplete({required bool value});

  String? get savedLanguageCode;
  Future<void> setLanguageCode(String code);
}

class AppPreferencesImpl implements AppPreferences {
  const AppPreferencesImpl(this._box);
  final Box<dynamic> _box;

  static const String _kOnboarding = 'onboarding_complete';
  static const String _kLanguage = 'language_code';

  @override
  bool get isOnboardingComplete =>
      _box.get(_kOnboarding, defaultValue: false) as bool;

  @override
  Future<void> setOnboardingComplete({required bool value}) =>
      _box.put(_kOnboarding, value);

  @override
  String? get savedLanguageCode => _box.get(_kLanguage) as String?;

  @override
  Future<void> setLanguageCode(String code) => _box.put(_kLanguage, code);
}
