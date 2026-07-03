enum OnboardingStatus {
  notSubmitted('Not sent to HQ'),
  pendingApproval('Pending HQ Approval'),
  approved('Active Customer');

  const OnboardingStatus(this.label);
  final String label;
}
