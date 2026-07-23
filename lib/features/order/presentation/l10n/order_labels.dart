import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_sync_status.dart';

/// Presentation-side localization for order domain enums — same pattern as
/// `lead_labels.dart`: domain keeps its English `label` for logs/tests,
/// UI renders the bundle-resolved `localizedLabel`.
extension QuotationSyncStatusL10n on QuotationSyncStatus {
  String get localizedLabel => switch (this) {
        QuotationSyncStatus.draft => 'orders.sync_status.draft'.tr,
        QuotationSyncStatus.readyToSubmit =>
          'orders.sync_status.ready_to_submit'.tr,
        QuotationSyncStatus.pendingSync => 'orders.sync_status.pending_sync'.tr,
        QuotationSyncStatus.syncing => 'orders.sync_status.syncing'.tr,
        QuotationSyncStatus.submitted => 'orders.sync_status.submitted'.tr,
        QuotationSyncStatus.accepted => 'orders.sync_status.accepted'.tr,
        QuotationSyncStatus.rejected => 'orders.sync_status.rejected'.tr,
        QuotationSyncStatus.failed => 'orders.sync_status.failed'.tr,
        QuotationSyncStatus.conflict => 'orders.sync_status.conflict'.tr,
      };
}
