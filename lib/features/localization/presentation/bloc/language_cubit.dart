import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/storage/hive/app_preferences.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';

class LanguageCubit extends Cubit<Locale> {
  final AppPreferences _prefs;

  // Reads saved language code from Hive preferences, defaulting to English ('en')
  LanguageCubit(this._prefs) : super(Locale(_prefs.savedLanguageCode ?? 'en')) {
    // Sync the localization service configuration on boot
    LocalizationService.instance.load(state.languageCode);
  }

  /// Triggers a hot language switch across the entire app ecosystem.
  ///
  /// 1. Reloads strings — [LocalizationService.load] calls `notifyListeners()`,
  ///    so every [LocalizedBuilder] in the live tree rebuilds instantly.
  /// 2. Persists the choice to the Hive-backed [AppPreferences] so it survives
  ///    restarts.
  /// 3. Emits the new [Locale] so `MaterialApp` updates its own locale /
  ///    directionality.
  Future<void> changeLanguage(String languageCode) async {
    await LocalizationService.instance.load(languageCode);
    await _prefs.setLanguageCode(languageCode);
    emit(Locale(languageCode));
  }
}
