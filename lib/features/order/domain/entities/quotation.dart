import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/off_visit_reason.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_status.dart';

/// A draft pre-sales document built in the Quotation Builder. Either
/// shop-scoped ([customerId] set) or lead-scoped ([leadId] set) — never
/// both. Replaces the old `PendingOrder` end-to-end.
class Quotation extends Equatable {
  const Quotation({
    required this.id,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.status,
    required this.sapDraftStatus,
    required this.validUntil,
    required this.createdAt,
    required this.updatedAt,
    this.customerId,
    this.shopName,
    this.leadId,
    this.leadDisplayName,
    this.offVisitReason,
    this.gpsLatitude,
    this.gpsLongitude,
  });

  final String id;
  final String? customerId;
  final String? shopName;
  final String? leadId;
  final String? leadDisplayName;
  final List<CartItem> lines;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final QuotationStatus status;
  final OffVisitReason? offVisitReason;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String sapDraftStatus;
  final DateTime validUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLeadScoped => leadId != null;

  @override
  List<Object?> get props => [
        id,
        customerId,
        shopName,
        leadId,
        leadDisplayName,
        lines,
        subtotal,
        discount,
        tax,
        total,
        status,
        offVisitReason,
        gpsLatitude,
        gpsLongitude,
        sapDraftStatus,
        validUntil,
        createdAt,
        updatedAt,
      ];
}
