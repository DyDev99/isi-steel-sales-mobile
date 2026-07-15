import 'package:flutter/widgets.dart';

/// Registry that maps a step's `targetKeyId` (a stable `const String`) to a live
/// [GlobalKey] on the widget to spotlight.
///
/// Two-part design keeps the domain framework-free: the catalog references only
/// the const string ids below, while the presentation layer resolves them to
/// keys here. Attach a key at the anchor with [wrap]; the overlay reads its
/// render box, and safely falls back to a centered bubble if the widget is
/// absent or unmounted.
abstract final class CoachKeys {
  // ── Anchor ids (must match CoachStepCatalog.targetKeyId values) ──────────
  static const String monthlyTarget = 'monthly_target';

  /// Whole-row anchors (kept for section-level overview steps).
  static const String quickActions = 'quick_actions';
  static const String myWork = 'my_work';
  

  // Quick-action items.
  static const String newQuote = 'qa_new_quote';
  static const String newLead = 'qa_new_lead';
  static const String depotStock = 'qa_depot_stock';

  // My-work items.
  static const String myLeads = 'mw_my_leads';
  static const String myVisits = 'mw_my_visits';
  static const String myCustomers = 'mw_my_customers';
  static const String orders = 'mw_orders';

  // App-bar items.
  static const String language = 'ab_language';
  static const String notification = 'ab_notification';
  static const String profile = 'ab_profile';

  static final Map<String, GlobalKey> _keys = {};

  /// The [GlobalKey] for [id], created on first request and reused after.
  static GlobalKey keyFor(String id) =>
      _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'coach_$id'));

  /// Wrap an anchor widget so the coach can locate it:
  /// `CoachKeys.wrap(CoachKeys.monthlyTarget, child: MonthlyTargetCard(...))`.
  static Widget wrap(String id, {required Widget child}) =>
      KeyedSubtree(key: keyFor(id), child: child);

  /// Current global bounds of [id]'s widget, or null when it isn't laid out.
  static Rect? rectFor(String id) {
    final ctx = _keys[id]?.currentContext;
    final box = ctx?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  /// The [BuildContext] of [id]'s widget (for `Scrollable.ensureVisible`).
  static BuildContext? contextFor(String id) => _keys[id]?.currentContext;
}
