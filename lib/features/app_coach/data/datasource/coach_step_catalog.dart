import 'package:isi_steel_sales_mobile/features/app_coach/domain/entities/coach_action.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/domain/entities/coach_step.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';

/// The tutorial script.
///
/// Defined as a `const` Dart list (not a bundled JSON asset) on purpose:
/// zero async, zero parse cost, no pubspec asset wiring, and the analyzer
/// verifies every localization/target id at compile time. Bump [coachVersion]
/// whenever the script changes materially so persisted progress migrates.
abstract final class CoachStepCatalog {
  /// Schema version — increment when steps are added/removed/reordered.
  static const int coachVersion = 2;

  static const List<CoachStep> steps = [
    CoachStep(
      id: 'welcome',
      titleKey: 'coach.welcome.title',
      messageKey: 'coach.welcome.message',
      ctaKey: 'coach.cta.start',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      order: 1,
    ),
    CoachStep(
      id: 'home_overview',
      titleKey: 'coach.home.title',
      messageKey: 'coach.home.message',
      ctaKey: 'coach.cta.next',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      order: 2,
    ),
    CoachStep(
      id: 'monthly_target',
      titleKey: 'coach.target.title',
      messageKey: 'coach.target.message',
      ctaKey: 'coach.cta.next',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      targetKeyId: CoachKeys.monthlyTarget,
      order: 3,
    ),
    CoachStep(
      id: 'quick_actions',
      titleKey: 'coach.quick_actions.title',
      messageKey: 'coach.quick_actions.message',
      ctaKey: 'coach.cta.next',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      targetKeyId: CoachKeys.quickActions,
      order: 4,
    ),
    CoachStep(
      id: 'new_quote',
      titleKey: 'coach.new_quote.title',
      messageKey: 'coach.new_quote.message',
      ctaKey: 'coach.cta.next',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      targetKeyId: CoachKeys.newQuote,
      order: 5,
    ),
    CoachStep(
      id: 'new_lead',
      titleKey: 'coach.new_lead.title',
      messageKey: 'coach.new_lead.message',
      ctaKey: 'coach.cta.skip_step',
      requiredAction: CoachAction.createLead,
      targetKeyId: CoachKeys.newLead,
      order: 6,
    ),
    CoachStep(
      id: 'depot_stock',
      titleKey: 'coach.depot_stock.title',
      messageKey: 'coach.depot_stock.message',
      ctaKey: 'coach.cta.next',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      targetKeyId: CoachKeys.depotStock,
      order: 7,
    ),
    CoachStep(
      id: 'my_leads',
      titleKey: 'coach.my_leads.title',
      messageKey: 'coach.my_leads.message',
      ctaKey: 'coach.cta.skip_step',
      requiredAction: CoachAction.openMyLeads,
      targetKeyId: CoachKeys.myLeads,
      order: 8,
    ),
    CoachStep(
      id: 'my_visits',
      titleKey: 'coach.my_visits.title',
      messageKey: 'coach.my_visits.message',
      ctaKey: 'coach.cta.skip_step',
      requiredAction: CoachAction.openMyVisits,
      targetKeyId: CoachKeys.myVisits,
      order: 9,
    ),
    CoachStep(
      id: 'my_customers',
      titleKey: 'coach.customers.title',
      messageKey: 'coach.customers.message',
      ctaKey: 'coach.cta.skip_step',
      requiredAction: CoachAction.openCustomers,
      targetKeyId: CoachKeys.myCustomers,
      order: 10,
    ),
    CoachStep(
      id: 'orders',
      titleKey: 'coach.orders.title',
      messageKey: 'coach.orders.message',
      ctaKey: 'coach.cta.skip_step',
      requiredAction: CoachAction.openOrders,
      targetKeyId: CoachKeys.orders,
      order: 11,
    ),
    CoachStep(
      id: 'language',
      titleKey: 'coach.language.title',
      messageKey: 'coach.language.message',
      ctaKey: 'coach.cta.next',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      targetKeyId: CoachKeys.language,
      order: 12,
    ),
    CoachStep(
      id: 'notification',
      titleKey: 'coach.notification.title',
      messageKey: 'coach.notification.message',
      ctaKey: 'coach.cta.next',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      targetKeyId: CoachKeys.notification,
      order: 13,
    ),
    CoachStep(
      id: 'profile',
      titleKey: 'coach.profile.title',
      messageKey: 'coach.profile.message',
      ctaKey: 'coach.cta.next',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      targetKeyId: CoachKeys.profile,
      order: 14,
    ),
    CoachStep(
      id: 'completed',
      titleKey: 'coach.done.title',
      messageKey: 'coach.done.message',
      ctaKey: 'coach.cta.finish',
      requiredAction: CoachAction.none,
      advanceOnCta: true,
      canSkip: false,
      order: 15,
    ),
  ];
}
