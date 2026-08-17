import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/data_domain.dart'
    show CustomizationMeasurement;
import 'package:isi_steel_sales_mobile/features/order/domain/entities/fulfillment.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/price_tier.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';

/// A single line in the cart / quotation.
///
/// A line can be a plain catalog product or a **customized** one — same base
/// [product], but with category-specific [measurements], a surface
/// [appearance]/finish, an optional technical [drawingImagePath], and free-form
/// [customizationDescription]. Customized lines never merge with plain ones
/// (each customization is its own line).
///
/// ## The line owns its SKU identity, not a reference to "a product"
///
/// [product] is one `products` row, and a `products` row *is* a sellable SKU:
/// its id is `{code}-{warehouseCode}`, so [skuId] already pins down material
/// **and** stock location together. [skuCode], [materialCode] and
/// [stockLocationCode] name the three levels explicitly rather than leaving
/// callers to re-derive them from the id, which is how a "productId" starts
/// being treated as a generic product somewhere downstream.
class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unit,
    required this.discountPercent,
    this.leadId,
    this.customerId,
    this.priceTier = PriceTier.standard,
    this.unitPriceOverride,
    this.fulfillment,
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

  /// Which of the SKU's price tiers this line was quoted at. Defaulted to
  /// [PriceTier.standard] because that is what the app quoted before an outlet
  /// tier existed — see the report's gaps section on `Customer.priceGroup`.
  final PriceTier priceTier;

  /// The price actually agreed for this line, frozen at the moment it was
  /// added.
  ///
  /// Null means "no snapshot taken yet" and falls back to the live catalog
  /// price, which is exactly how every line behaved before this field existed —
  /// so rows written by an older build keep pricing the way they always did.
  ///
  /// Once set it is authoritative, and deliberately so: a quotation the rep
  /// printed and handed to a customer must still say the same number tomorrow,
  /// even after SAP pushes a price delta into the `prices` table underneath it.
  final double? unitPriceOverride;

  /// Pickup/delivery terms for this line, or null when the rep added it
  /// straight from the product grid without opening the fulfillment step.
  final ShipmentSelection? fulfillment;

  // ── Customization (null / false for a plain catalog line) ─────────────
  final bool isCustomized;
  final CustomizationMeasurement? measurements;
  final String? appearance;
  final String? drawingImagePath;
  final String? customizationDescription;

  // ── SKU identity ──────────────────────────────────────────────────────

  /// The exact sellable SKU: `products.id`, which equals `products.sku`.
  /// Unique per (material × warehouse).
  String get skuId => product.id;

  /// `products.sku` as SAP publishes it.
  String get skuCode => product.sku;

  /// The SAP material number, shared by every warehouse row of this material.
  String get materialCode => product.materialCode;

  /// The material/variant code, one level above the SKU: the same physical
  /// article regardless of which warehouse holds it.
  String get productCode => product.code;

  /// Where this SKU's stock sits — `products.warehouse_code`, the key the
  /// `stock` table is partitioned by.
  String get stockLocationCode => product.warehouseCode;

  // ── Money ─────────────────────────────────────────────────────────────

  double get unitPrice =>
      unitPriceOverride ?? product.pricing.effectivePrice(priceTier);
  double get lineSubtotal => unitPrice * quantity;
  double get lineDiscount => lineSubtotal * (discountPercent / 100);
  double get lineTotal => lineSubtotal - lineDiscount;

  CartItem copyWith({
    double? quantity,
    String? unit,
    double? discountPercent,
    PriceTier? priceTier,
    double? Function()? unitPriceOverride,
    ShipmentSelection? Function()? fulfillment,
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
      priceTier: priceTier ?? this.priceTier,
      // Nullable-setter closures rather than plain optionals: clearing a price
      // snapshot back to "use the live catalog price" has to be expressible,
      // and `unitPriceOverride: null` cannot say that.
      unitPriceOverride: unitPriceOverride != null
          ? unitPriceOverride()
          : this.unitPriceOverride,
      fulfillment: fulfillment != null ? fulfillment() : this.fulfillment,
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
        priceTier,
        unitPriceOverride,
        fulfillment,
        isCustomized,
        measurements,
        appearance,
        drawingImagePath,
        customizationDescription,
      ];
}
