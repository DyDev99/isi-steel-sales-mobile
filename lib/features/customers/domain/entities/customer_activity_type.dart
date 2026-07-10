enum CustomerActivityType {
  call('Call', 'call'),
  whatsapp('WhatsApp', 'whatsapp'),
  visit('Visit', 'visit'),
  note('Note', 'note'),
  opportunityCreated('Opportunity Created', 'opportunity'),
  order('Order', 'order');

  const CustomerActivityType(this.label, this.value);
  final String label;
  final String value;

  static CustomerActivityType fromValue(String value) =>
      CustomerActivityType.values.firstWhere((t) => t.value == value,
          orElse: () => CustomerActivityType.note);
}
