import 'package:equatable/equatable.dart';

/// A product category shown as a horizontal quick-filter chip.
class ProductCategory extends Equatable {
  const ProductCategory({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
