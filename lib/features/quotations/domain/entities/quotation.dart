import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/quotations/data/models/quotation_status.dart';

class Quotation extends Equatable {
  const Quotation({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.statusGroup,
    this.currency,
    required this.net,
    required this.lineCount,
    this.validTo,
    required this.createdAt,
    required this.updatedAt,
    this.statusDisplay,
  });

  final String id;
  final String number;
  final String customerId;
  final String customerName;
  final QuotationStatus status;
  final QuotationStatusGroup statusGroup;
  final String? currency;
  final double net;
  final int lineCount;
  final DateTime? validTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? statusDisplay;

  @override
  List<Object?> get props => [
        id,
        number,
        customerId,
        customerName,
        status,
        statusGroup,
        currency,
        net,
        lineCount,
        validTo,
        createdAt,
        updatedAt,
        statusDisplay,
      ];
}

class QuotationDetail extends Quotation {
  const QuotationDetail({
    required super.id,
    required super.number,
    required super.customerId,
    required super.customerName,
    required super.status,
    required super.statusGroup,
    super.currency,
    required super.net,
    required super.lineCount,
    super.validTo,
    required super.createdAt,
    required super.updatedAt,
    super.statusDisplay,
    this.shipmentType,
    this.shipTo,
    this.paymentTerm,
    this.customerReference,
    this.remarks,
    this.lines = const [],
    this.totals,
    this.warnings = const [],
    this.manualDiscountLimitPercent = 0.0,
    this.lineDiscountCapPercent = 0.0,
    this.requiredApprovalLevel = 0,
    this.revision = 0,
    this.decisionReason,
  });

  final String? shipmentType;
  final String? shipTo;
  final String? paymentTerm;
  final String? customerReference;
  final String? remarks;
  final List<QuotationLine> lines;
  final QuotationTotals? totals;
  final List<QuotationWarning> warnings;
  final double manualDiscountLimitPercent;
  final double lineDiscountCapPercent;
  final int requiredApprovalLevel;
  final int revision;
  final String? decisionReason;

  @override
  List<Object?> get props => [
        ...super.props,
        shipmentType,
        shipTo,
        paymentTerm,
        customerReference,
        remarks,
        lines,
        totals,
        warnings,
        manualDiscountLimitPercent,
        lineDiscountCapPercent,
        requiredApprovalLevel,
        revision,
        decisionReason,
      ];
}

class QuotationLine extends Equatable {
  const QuotationLine({
    required this.lineId,
    required this.materialNumber,
    required this.materialDescription,
    required this.quantity,
    required this.unit,
    this.priceAmount,
    this.priceCurrency,
    this.pricePricingUnit,
    this.priceConditionUnit,
    required this.gross,
    required this.discountTotal,
    required this.net,
    this.discounts = const [],
  });

  final String lineId;
  final String materialNumber;
  final String materialDescription;
  final double quantity;
  final String unit;
  
  final double? priceAmount;
  final String? priceCurrency;
  final double? pricePricingUnit;
  final String? priceConditionUnit;

  final double gross;
  final double discountTotal;
  final double net;
  
  final List<QuotationDiscount> discounts;

  @override
  List<Object?> get props => [
        lineId,
        materialNumber,
        materialDescription,
        quantity,
        unit,
        priceAmount,
        priceCurrency,
        pricePricingUnit,
        priceConditionUnit,
        gross,
        discountTotal,
        net,
        discounts,
      ];
}

class QuotationDiscount extends Equatable {
  const QuotationDiscount({
    required this.kind,
    required this.percent,
    this.reason,
    this.amount,
  });

  final String kind;
  final double percent;
  final String? reason;
  final double? amount;

  @override
  List<Object?> get props => [kind, percent, reason, amount];
}

class QuotationTotals extends Equatable {
  const QuotationTotals({
    required this.currency,
    required this.gross,
    required this.discountTotal,
    required this.net,
    required this.isEstimate,
    this.tax,
  });

  final String currency;
  final double gross;
  final double discountTotal;
  final double net;
  final bool isEstimate;
  final double? tax;

  @override
  List<Object?> get props => [
        currency,
        gross,
        discountTotal,
        net,
        isEstimate,
        tax,
      ];
}

class QuotationWarning extends Equatable {
  const QuotationWarning({
    required this.code,
    required this.lineId,
  });

  final String code;
  final String lineId;

  @override
  List<Object?> get props => [code, lineId];
}
