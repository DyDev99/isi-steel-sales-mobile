import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/budget_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/credit_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_source.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_sub_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/shop_type.dart';

/// Presentation-side localization for lead domain enums.
///
/// The domain layer stays pure Dart (no localization imports —
/// ENGINEERING_STANDARD §3), so the enums keep their English `label` fields
/// for logs/tests/storage. UI renders these `localizedLabel`s instead, which
/// resolve through the bundle and re-render live on language change.
extension PipelineStageL10n on PipelineStage {
  String get localizedLabel => switch (this) {
        PipelineStage.leads => 'leads.enums.stage_leads'.tr,
        PipelineStage.opportunities => 'leads.enums.stage_opportunities'.tr,
        PipelineStage.won => 'leads.enums.stage_won'.tr,
      };
}

extension PriorityL10n on Priority {
  String get localizedLabel => switch (this) {
        Priority.low => 'leads.filter.low'.tr,
        Priority.medium => 'leads.filter.medium'.tr,
        Priority.high => 'leads.filter.high'.tr,
      };
}

extension LeadSourceL10n on LeadSource {
  String get localizedLabel => switch (this) {
        LeadSource.fieldVisit => 'leads.enums.source_field_visit'.tr,
        LeadSource.referral => 'leads.enums.source_referral'.tr,
        LeadSource.coldCall => 'leads.enums.source_cold_call'.tr,
        LeadSource.website => 'leads.enums.source_website'.tr,
        LeadSource.tradeShow => 'leads.enums.source_trade_show'.tr,
        LeadSource.walkIn => 'leads.enums.source_walk_in'.tr,
      };
}

extension OnboardingStatusL10n on OnboardingStatus {
  String get localizedLabel => switch (this) {
        OnboardingStatus.notSubmitted =>
          'leads.enums.onboarding_not_submitted'.tr,
        OnboardingStatus.pendingApproval =>
          'leads.enums.onboarding_pending_approval'.tr,
        OnboardingStatus.approved => 'leads.enums.onboarding_approved'.tr,
      };
}

extension CreditStatusL10n on CreditStatus {
  String get localizedLabel => switch (this) {
        CreditStatus.notApplicable => 'leads.enums.credit_not_applicable'.tr,
        CreditStatus.pending => 'leads.enums.credit_pending'.tr,
        CreditStatus.approved => 'leads.enums.credit_approved'.tr,
        CreditStatus.rejected => 'leads.enums.credit_rejected'.tr,
      };
}

extension ShopTypeL10n on ShopType {
  String get localizedLabel => switch (this) {
        ShopType.retailShop => 'leads.enums.shop_retail'.tr,
        ShopType.wholesaleDepot => 'leads.enums.shop_wholesale_depot'.tr,
        ShopType.hardwareStore => 'leads.enums.shop_hardware_store'.tr,
        ShopType.constructionSupplier =>
          'leads.enums.shop_construction_supplier'.tr,
        ShopType.distributor => 'leads.enums.shop_distributor'.tr,
      };
}

extension OpportunitySubStageL10n on OpportunitySubStage {
  String get localizedLabel => switch (this) {
        OpportunitySubStage.qualifying => 'leads.enums.sub_qualifying'.tr,
        OpportunitySubStage.quoteSent => 'leads.enums.sub_quote_sent'.tr,
        OpportunitySubStage.negotiating => 'leads.enums.sub_negotiating'.tr,
      };
}

extension BudgetStatusL10n on BudgetStatus {
  String get localizedLabel => switch (this) {
        BudgetStatus.confirmed => 'leads.enums.budget_confirmed'.tr,
        BudgetStatus.likely => 'leads.enums.budget_likely'.tr,
        BudgetStatus.notYet => 'leads.not_yet'.tr,
      };
}
