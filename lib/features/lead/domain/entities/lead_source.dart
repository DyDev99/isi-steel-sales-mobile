enum LeadSource {
  fieldVisit('Field Visit'),
  referral('Referral'),
  coldCall('Cold Call'),
  website('Website'),
  tradeShow('Trade Show'),
  walkIn('Walk-in');

  const LeadSource(this.label);
  final String label;
}
