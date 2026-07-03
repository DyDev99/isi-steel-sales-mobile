import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Global, reactive translation store. It's a [ChangeNotifier] so that any
/// widget can rebuild the instant the language changes — wrap a subtree in
/// [LocalizedBuilder] (which listens here) and every `.tr` inside re-evaluates
/// live, no app restart and no re-navigation required. Deliberately
/// context-free (a singleton) so the `.tr` String extension works anywhere.
class LocalizationService extends ChangeNotifier {
  // Global singleton instance so the String extension can access it context-free
  static final LocalizationService instance = LocalizationService._internal();
  LocalizationService._internal();

  Map<String, String> _localizedStrings = {};
  String _currentLanguageCode = 'en';

  String get currentLanguageCode => _currentLanguageCode;

  /// Loads, parses, and flattens nested JSON structures from assets, then
  /// notifies listeners so the live view tree rebuilds with the new language.
  Future<void> load(String languageCode) async {
    _currentLanguageCode = languageCode;
    try {
      String jsonString = await rootBundle.loadString('assets/lang/$languageCode.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = {};
      _flatten(jsonMap, ''); // Recursively flattens maps
    } catch (e) {
      _localizedStrings = {};
    }
    notifyListeners();
  }

  // Helper method to turn nested objects into "parent.child.key" strings
  void _flatten(Map<String, dynamic> jsonMap, String prefix) {
    jsonMap.forEach((key, value) {
      final String newKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _flatten(value, newKey);
      } else {
        _localizedStrings[newKey] = value.toString();
      }
    });
  }

  /// Looks up translation keys. Returns the original key if missing.
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

/// THIS IS CRITICAL: This activates the 'key'.tr syntax anywhere in your project!
extension LocalizationStringExtension on String {
  String get tr => LocalizationService.instance.translate(this);
}