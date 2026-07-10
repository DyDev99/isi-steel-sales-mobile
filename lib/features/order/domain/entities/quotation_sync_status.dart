/// The outbound (local → SAP) sync lifecycle of a quotation, tracked
/// independently of [QuotationStatus] (draft/saved/converted) so the existing
/// quotation persistence stays untouched.
///
/// Flow (states are never skipped):
///   pendingSync → syncing → accepted
///                        └→ rejected   (SAP business rejection — user action)
///                        └→ failed     (transport failure after max retries)
///   pendingSync → conflict            (SAP state diverged — user must resolve)
///
/// `draft`/`readyToSubmit` describe a quotation that has NOT yet been enqueued;
/// they exist so the same enum can label a quotation at any point in its life.
enum QuotationSyncStatus {
  draft,
  readyToSubmit,
  pendingSync,
  syncing,
  submitted,
  accepted,
  rejected,
  failed,
  conflict;

  /// Waiting in, or actively moving through, the outbound queue.
  bool get isPending =>
      this == pendingSync || this == syncing || this == submitted;

  /// Reached a final SAP outcome — no further automatic processing.
  bool get isTerminal => this == accepted;

  /// Stuck and needs the user to decide (retry / resolve) — surfaced in the
  /// Pending Sync center, never auto-resolved.
  bool get needsUserAction =>
      this == failed || this == rejected || this == conflict;

  /// A locally-editable quotation not yet handed to the sync queue — what the
  /// Continue-Working card offers to resume.
  bool get isDraft => this == draft || this == readyToSubmit;

  String get label => switch (this) {
        draft => 'Draft',
        readyToSubmit => 'Ready to submit',
        pendingSync => 'Pending sync',
        syncing => 'Syncing…',
        submitted => 'Submitted',
        accepted => 'SAP accepted',
        rejected => 'SAP rejected',
        failed => 'Sync failed',
        conflict => 'Conflict',
      };

  static QuotationSyncStatus fromName(String? name) =>
      values.asNameMap()[name] ?? draft;
}
