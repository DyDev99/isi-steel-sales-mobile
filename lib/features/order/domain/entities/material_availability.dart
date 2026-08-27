import 'package:equatable/equatable.dart';

/// Where a material's sellability check currently stands.
///
/// Deliberately four states, not a bool. "Not yet asked", "asking" and "the
/// answer is no" are three different things to a rep standing in front of a
/// customer, and collapsing them means a card that has not been checked looks
/// identical to one SAP refused.
enum MaterialStockStatus {
  /// Never asked. The default for every material the rep is only browsing —
  /// the check is a live SAP round trip and is spent on commitment, not on
  /// scrolling.
  unknown,

  checking,

  /// SAP says this may be sold into the sales area.
  available,

  /// SAP says it may not. **This is not a quantity.** There is no on-hand
  /// figure anywhere in this API; the verdict is about whether the material is
  /// sellable at all, which is a different question from how much is in the
  /// yard.
  unavailable,
}

/// One line of SAP's reasoning.
///
/// The working, not just the conclusion: `SALES_VIEW` failing with "Material is
/// not extended to sales area 1000/10" is the difference between a rep being
/// told "cannot sell this" and being told something they can act on by phoning
/// the right person.
class MaterialAvailabilityCheck extends Equatable {
  const MaterialAvailabilityCheck({
    required this.sequence,
    required this.checkId,
    required this.status,
    required this.message,
    required this.isVerdict,
  });

  final String sequence;
  final String checkId;

  /// SAP's own status letter: `S` success, `E` error.
  final String status;

  final String message;

  /// True for the single concluding check. The others are how it got there.
  final bool isVerdict;

  bool get isError => status.toUpperCase() == 'E';

  /// A complaint about what *we* sent, not about the material.
  ///
  /// SAP answers `INPUT_VKORG` / `INPUT_VTWEG` when the sales-area parameters
  /// are missing, and it does so with **HTTP 200** — the request succeeded, the
  /// validation simply never ran. Reading that as a business verdict is the
  /// documented trap.
  bool get isInputProblem => checkId.toUpperCase().startsWith('INPUT_');

  @override
  List<Object?> get props => [sequence, checkId, status, message, isVerdict];
}

/// SAP's live sellability verdict for one material in one sales area.
///
/// **Not a stock level.** The materials API exposes no on-hand quantity, no
/// warehouse balance and no ATP figure. What it exposes is this: whether the
/// ERP will accept an order line for the material, and why not when it will
/// not.
class MaterialAvailability extends Equatable {
  const MaterialAvailability({
    required this.material,
    required this.isSellable,
    required this.summary,
    required this.checks,
    this.status = MaterialStockStatus.unknown,
  });

  /// The in-flight placeholder, so a card can show a spinner against the exact
  /// material being checked rather than a screen-wide loading state.
  const MaterialAvailability.checking(this.material)
      : isSellable = false,
        summary = '',
        checks = const [],
        status = MaterialStockStatus.checking;

  final String material;
  final bool isSellable;

  /// SAP's own one-line conclusion, already written for a human.
  final String summary;

  final List<MaterialAvailabilityCheck> checks;

  final MaterialStockStatus status;

  /// The concluding check, or null when SAP returned only working.
  MaterialAvailabilityCheck? get verdict {
    for (final check in checks) {
      if (check.isVerdict) return check;
    }
    return null;
  }

  /// Everything that actually blocked the sale, in SAP's own order — the
  /// verdict excluded, because it restates rather than explains.
  List<MaterialAvailabilityCheck> get blockingChecks =>
      checks.where((c) => c.isError && !c.isVerdict).toList(growable: false);

  /// The check failed because the app did not send the sales area, not because
  /// the material is unsellable.
  ///
  /// SAP needs `salesOrg`, `disChannel` and `division`; without them it answers
  /// "Validation not performed. Mandatory input parameters are missing." with
  /// `isSellable: false`. That `false` is the absence of an answer wearing the
  /// shape of one.
  ///
  /// Kept as its own flag so the reason survives into logs and the detail sheet
  /// even where the badge treats it as a plain "no stock" — a rep should not be
  /// the last person to find out the handset never asked the question properly.
  bool get isInputIncomplete => checks.any((c) => c.isInputProblem);

  /// The single line worth putting under a badge.
  ///
  /// Prefers the first genuine blocker over the verdict, because the verdict
  /// only ever restates the summary while the blocker names the cause.
  String get reason {
    final blocking = blockingChecks;
    if (blocking.isNotEmpty) return blocking.first.message;
    return verdict?.message ?? summary;
  }

  @override
  List<Object?> get props => [material, isSellable, summary, checks, status];
}
