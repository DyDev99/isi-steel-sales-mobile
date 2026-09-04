import 'dart:convert';

import 'package:isi_steel_sales_mobile/core/database/hive/local_cache.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';

/// Stores the one registration form the rep currently has open.
///
/// ## Why Hive and not Drift
///
/// A draft is not a business record — it is UI state that happens to survive
/// the process. It has no schema anyone queries, it is thrown away the moment
/// the registration is accepted, and giving it a Drift table would mean a
/// migration every time the form grows a field. Layer 2, per ADR-009.
///
/// ## Why no TTL
///
/// [CustomerReferenceCache] expires because a stale catalogue is wrong.
/// A stale draft is not wrong, it is unfinished — a rep who starts a
/// registration on Friday and returns to the shop on Monday must find their
/// typing intact. It is cleared on success, and only on success.
///
/// ## Why exactly one
///
/// A single key, not a list. The wizard is modal and the rep can only be
/// standing in one shop at a time; a queue of half-filled forms would need a
/// picker, and the reliable outcome of that is a rep submitting the wrong one.
class BpDraftCache {
  const BpDraftCache(this._cache);

  final LocalCache _cache;

  static const String _key = 'bp_registration_draft';

  /// The saved form, or null when there is none or it cannot be read.
  ///
  /// A decode failure returns null **and clears the entry**. A draft written by
  /// an older build can be structurally unreadable, and leaving it in place
  /// would fail every subsequent open the same way — the rep would face a form
  /// that never loads and no way to reset it from the UI.
  Future<BpCustomerDraft?> read() async {
    final raw = _cache.get<String>(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await clear();
        return null;
      }
      return BpCustomerDraft.fromDraftJson(decoded.cast<String, dynamic>());
    } on Object {
      await clear();
      return null;
    }
  }

  /// Writes the form. Swallows failures on purpose — this is called on every
  /// keystroke's debounce, and an exception here would surface as the rep's
  /// typing throwing.
  Future<void> write(BpCustomerDraft draft) async {
    try {
      // Encoded as a JSON string rather than a nested map: Hive round-trips
      // nested structures as `Map<dynamic, dynamic>`, and the cast back is
      // where this kind of cache usually starts throwing.
      await _cache.set(_key, jsonEncode(draft.toDraftJson()));
    } on Object {
      // Intentionally ignored. The form is still in memory and still correct;
      // the only thing lost is resume-after-kill, which is not worth an error
      // banner mid-sentence.
    }
  }

  Future<void> clear() async {
    try {
      await _cache.remove(_key);
    } on Object {
      // Same reasoning as [write]. Worst case a stale draft is offered once
      // more and [read] discards it.
    }
  }

  /// True when there is something to resume. Used to decide whether the form
  /// should say so, rather than opening pre-filled with no explanation — which
  /// reads as a bug.
  bool get hasDraft {
    final raw = _cache.get<String>(_key);
    return raw != null && raw.isNotEmpty;
  }
}
