enum CreditStatus {
  notApplicable('Not applicable'),
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const CreditStatus(this.label);
  final String label;
}
