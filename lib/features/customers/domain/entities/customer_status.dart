enum CustomerStatus {
  active('Active'),
  dormant('Dormant'),
  creditHold('Credit Hold');

  const CustomerStatus(this.label);
  final String label;
}
