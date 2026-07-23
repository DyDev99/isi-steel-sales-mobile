import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/territory_type.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

/// Presentation-side localization for my_visits domain enums.
///
/// The domain layer stays pure Dart (no localization imports —
/// ENGINEERING_STANDARD §3), so its `label` getters keep their English values
/// for logs/tests. UI code renders these `localizedLabel`s instead, which
/// resolve through the bundle and re-render live on language change.
extension VisitStatusL10n on VisitStatus {
  String get localizedLabel => switch (this) {
        VisitStatus.pending => 'my_visits.status.pending'.tr,
        VisitStatus.enRoute => 'my_visits.status.en_route'.tr,
        VisitStatus.arrived => 'my_visits.status.arrived'.tr,
        VisitStatus.checkedIn => 'my_visits.status.checked_in'.tr,
        VisitStatus.checkedOut => 'my_visits.status.completed'.tr,
        VisitStatus.missed => 'my_visits.status.missed'.tr,
      };
}

extension TerritoryTypeL10n on TerritoryType {
  String get localizedLabel => switch (this) {
        TerritoryType.urban => 'my_visits.territory.urban'.tr,
        TerritoryType.suburban => 'my_visits.territory.suburban'.tr,
        TerritoryType.industrial => 'my_visits.territory.industrial'.tr,
        TerritoryType.rural => 'my_visits.territory.rural'.tr,
      };
}

/// Localized ordinal for a stop's sequence number ("1st" / "ទី1").
///
/// English composes `{n}{suffix}` from the suffix keys; Khmer's template is
/// `ទី{n}` (a prefix — it simply ignores the suffix parameter). Languages that
/// need neither define the suffix keys as empty strings.
String localizedOrdinal(int number) {
  final String suffixKey;
  if (number % 100 >= 11 && number % 100 <= 13) {
    suffixKey = 'my_visits.ordinal.th';
  } else {
    suffixKey = switch (number % 10) {
      1 => 'my_visits.ordinal.st',
      2 => 'my_visits.ordinal.nd',
      3 => 'my_visits.ordinal.rd',
      _ => 'my_visits.ordinal.th',
    };
  }
  return 'my_visits.ordinal.template'
      .trParams({'n': number, 'suffix': suffixKey.tr});
}
