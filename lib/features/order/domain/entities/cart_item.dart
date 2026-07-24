import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/data_domain.dart'
    show CustomizationMeasurement;
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';

/// A single line in the cart / quotation.
///
/// A line can be a plain catalog product or a **customized** one — same base
/// [product], but with category-specific [measurements], a surface
/// [appearance]/finish, an optional technical [drawingImagePath], and free-form
/// [customizationDescription]. Customized lines never merge with plain ones
/// (each customization is its own line).
class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unit,
    required this.discountPercent,
    this.leadId,
    this.customerId,
    this.isCustomized = false,
    this.measurements,
    this.appearance,
    this.drawingImagePath,
    this.customizationDescription,
  });

  final String id;
  final Product product;
  final double quantity;
  final String unit;
  final double discountPercent;
  final String? leadId;
  final String? customerId;

  // ── Customization (null / false for a plain catalog line) ─────────────
  final bool isCustomized;
  final CustomizationMeasurement? measurements;
  final String? appearance;
  final String? drawingImagePath;
  final String? customizationDescription;

  double get unitPrice => product.effectivePrice;
  double get lineSubtotal => unitPrice * quantity;
  double get lineDiscount => lineSubtotal * (discountPercent / 100);
  double get lineTotal => lineSubtotal - lineDiscount;

  CartItem copyWith({
    double? quantity,
    String? unit,
    double? discountPercent,
    bool? isCustomized,
    CustomizationMeasurement? measurements,
    String? appearance,
    String? drawingImagePath,
    String? customizationDescription,
  }) {
    return CartItem(
      id: id,
      product: product,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      discountPercent: discountPercent ?? this.discountPercent,
      leadId: leadId,
      customerId: customerId,
      isCustomized: isCustomized ?? this.isCustomized,
      measurements: measurements ?? this.measurements,
      appearance: appearance ?? this.appearance,
      drawingImagePath: drawingImagePath ?? this.drawingImagePath,
      customizationDescription:
          customizationDescription ?? this.customizationDescription,
    );
  }

  @override
  List<Object?> get props => [
        id,
        product,
        quantity,
        unit,
        discountPercent,
        leadId,
        customerId,
        isCustomized,
        measurements,
        appearance,
        drawingImagePath,
        customizationDescription,
      ];
}
