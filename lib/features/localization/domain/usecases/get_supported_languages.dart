import 'package:isi_steel_sales_mobile/features/localization/domain/entities/language_entity.dart';
import 'package:isi_steel_sales_mobile/features/localization/domain/repositories/language_repository.dart';

/// Returns the catalog of languages the app ships translations for.
class GetSupportedLanguages {
  const GetSupportedLanguages(this._repository);
  final LanguageRepository _repository;

  List<LanguageEntity> call() => _repository.getSupportedLanguages();
}
