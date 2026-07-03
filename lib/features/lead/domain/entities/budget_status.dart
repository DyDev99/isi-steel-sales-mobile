enum BudgetStatus {
  confirmed('Confirmed'),
  likely('Likely'),
  notYet('Not yet');

  const BudgetStatus(this.label);
  final String label;
}
