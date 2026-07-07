import 'package:equatable/equatable.dart';

/// A selectable discount preset shown as a chip on the Discount Card.
class DiscountOption extends Equatable {
  const DiscountOption({
    required this.id,
    required this.label,
    required this.percentage,
    this.isDefault = false,
  });

  final String id;
  final String label;

  /// e.g. `10` for 10%.
  final double percentage;
  final bool isDefault;

  @override
  List<Object?> get props => [id, label, percentage, isDefault];
}
