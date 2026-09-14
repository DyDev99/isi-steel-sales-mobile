

enum QuotationStatus {
  draft('Draft'),
  returned('Returned'),
  pendingApproval('PendingApproval'),
  approved('Approved'),
  submittingToSap('SubmittingToSap'),
  quoted('Quoted'),
  sapFailed('SapFailed'),
  submittingOrder('SubmittingOrder'),
  orderFailed('OrderFailed'),
  accepted('Accepted'),
  ordered('Ordered'),
  rejected('Rejected'),
  cancelled('Cancelled'),
  lost('Lost'),
  expired('Expired'),
  unknown('Unknown');

  final String value;
  const QuotationStatus(this.value);

  static QuotationStatus fromValue(String? value) {
    if (value == null) return QuotationStatus.unknown;
    return QuotationStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => QuotationStatus.unknown,
    );
  }
}

enum QuotationStatusGroup {
  drafts('Drafts'),
  waiting('Waiting'),
  withCustomer('WithCustomer'),
  won('Won'),
  closed('Closed'),
  unknown('Unknown');

  final String value;
  const QuotationStatusGroup(this.value);

  static QuotationStatusGroup fromValue(String? value) {
    if (value == null) return QuotationStatusGroup.unknown;
    return QuotationStatusGroup.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => QuotationStatusGroup.unknown,
    );
  }
}
