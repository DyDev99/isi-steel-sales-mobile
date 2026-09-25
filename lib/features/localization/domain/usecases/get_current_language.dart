import 'package:isi_steel_sales_mobile/features/localization/domain/entities/language_entity.dart';
import 'package:isi_steel_sales_mobile/features/localization/domain/repositories/language_repository.dart';

/// Returns the active language (saved selection, or English by default).
/// Synchronous — used to seed state before the first frame.
class GetCurrentLanguage {
  const GetCurrentLanguage(this._repository);
  final LanguageRepository _repository;

  LanguageEntity call() => _repository.getCurrentLanguage();
}
