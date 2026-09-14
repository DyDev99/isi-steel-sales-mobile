import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/quotations/data/models/quotation_status.dart';

class QuotationDto {
  const QuotationDto({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.statusGroup,
    required this.currency,
    required this.net,
    required this.lineCount,
    required this.validTo,
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

  factory QuotationDto.fromJson(DataMap json) => QuotationDto(
        id: json['id'] as String,
        number: json['number'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        status: QuotationStatus.fromValue(json['status'] as String?),
        statusGroup: QuotationStatusGroup.fromValue(json['statusGroup'] as String?),
        currency: json['currency'] as String?,
        net: (json['net'] as num?)?.toDouble() ?? 0.0,
        lineCount: json['lineCount'] as int? ?? 0,
        validTo: json['validTo'] != null ? DateTime.parse(json['validTo'] as String) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        statusDisplay: json['statusDisplay'] as String?,
      );
}

class QuotationDetailDto extends QuotationDto {
  const QuotationDetailDto({
    required super.id,
    required super.number,
    required super.customerId,
    required super.customerName,
    required super.status,
    required super.statusGroup,
    required super.currency,
    required super.net,
    required super.lineCount,
    required super.validTo,
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
  final List<QuotationLineDto> lines;
  final QuotationTotalsDto? totals;
  final List<QuotationWarningDto> warnings;
  final double manualDiscountLimitPercent;
  final double lineDiscountCapPercent;
  final int requiredApprovalLevel;
  final int revision;
  final String? decisionReason;

  factory QuotationDetailDto.fromJson(DataMap json) {
    return QuotationDetailDto(
      id: json['id'] as String? ?? json['quotationId'] as String? ?? '', // Preview endpoint uses quotationId
      number: json['number'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      status: QuotationStatus.fromValue(json['status'] as String?),
      statusGroup: QuotationStatusGroup.fromValue(json['statusGroup'] as String?),
      currency: json['currency'] as String?,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
      lineCount: json['lineCount'] as int? ?? 0,
      validTo: json['validTo'] != null ? DateTime.parse(json['validTo'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      statusDisplay: json['statusDisplay'] as String?,
      shipmentType: json['shipmentType'] as String?,
      shipTo: json['shipTo'] as String?,
      paymentTerm: json['paymentTerm'] as String?,
      customerReference: json['customerReference'] as String?,
      remarks: json['remarks'] as String?,
      lines: (json['lines'] as List<dynamic>? ?? [])
          .map((e) => QuotationLineDto.fromJson(e as DataMap))
          .toList(),
      totals: json['totals'] != null ? QuotationTotalsDto.fromJson(json['totals'] as DataMap) : null,
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((e) => QuotationWarningDto.fromJson(e as DataMap))
          .toList(),
      manualDiscountLimitPercent: (json['manualDiscountLimitPercent'] as num?)?.toDouble() ?? 0.0,
      lineDiscountCapPercent: (json['lineDiscountCapPercent'] as num?)?.toDouble() ?? 0.0,
      requiredApprovalLevel: json['requiredApprovalLevel'] as int? ?? 0,
      revision: json['revision'] as int? ?? 0,
      decisionReason: json['decisionReason'] as String?,
    );
  }
}

class QuotationLineDto {
  const QuotationLineDto({
    required this.lineId,
    required this.materialNumber,
    required this.materialDescription,
    required this.quantity,
    required this.unit,
    this.priceAmount,
    this.priceCurrency,
    this.pricePricingUnit,
    this.priceConditionUnit,
    this.gross = 0.0,
    this.discountTotal = 0.0,
    this.net = 0.0,
    this.discounts = const [],
  });

  final String lineId;
  final String materialNumber;
  final String materialDescription;
  final double quantity;
  final String unit;
  
  // The 4-part price
  final double? priceAmount;
  final String? priceCurrency;
  final double? pricePricingUnit;
  final String? priceConditionUnit;

  // Computed amounts
  final double gross;
  final double discountTotal;
  final double net;
  
  final List<QuotationDiscountDto> discounts;

  factory QuotationLineDto.fromJson(DataMap json) => QuotationLineDto(
        lineId: json['lineId'] as String? ?? json['id'] as String? ?? '',
        materialNumber: json['materialNumber'] as String? ?? '',
        materialDescription: json['materialDescription'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? '',
        priceAmount: (json['priceAmount'] as num?)?.toDouble(),
        priceCurrency: json['priceCurrency'] as String?,
        pricePricingUnit: (json['pricePricingUnit'] as num?)?.toDouble(),
        priceConditionUnit: json['priceConditionUnit'] as String?,
        gross: (json['gross'] as num?)?.toDouble() ?? 0.0,
        discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0.0,
        net: (json['net'] as num?)?.toDouble() ?? 0.0,
        discounts: (json['discounts'] as List<dynamic>? ?? [])
            .map((e) => QuotationDiscountDto.fromJson(e as DataMap))
            .toList(),
      );
}

class QuotationDiscountDto {
  const QuotationDiscountDto({
    required this.kind,
    required this.percent,
    this.reason,
    this.amount,
  });

  final String kind; // e.g. Manual, Agreement
  final double percent;
  final String? reason;
  final double? amount;

  factory QuotationDiscountDto.fromJson(DataMap json) => QuotationDiscountDto(
        kind: json['kind'] as String? ?? 'Unknown',
        percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
        reason: json['reason'] as String?,
        amount: (json['amount'] as num?)?.toDouble(),
      );
}

class QuotationTotalsDto {
  const QuotationTotalsDto({
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

  factory QuotationTotalsDto.fromJson(DataMap json) => QuotationTotalsDto(
        currency: json['currency'] as String? ?? '',
        gross: (json['gross'] as num?)?.toDouble() ?? 0.0,
        discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0.0,
        net: (json['net'] as num?)?.toDouble() ?? 0.0,
        isEstimate: json['isEstimate'] as bool? ?? false,
        tax: (json['tax'] as num?)?.toDouble(),
      );
}

class QuotationWarningDto {
  const QuotationWarningDto({
    required this.code,
    required this.lineId,
  });

  final String code;
  final String lineId;

  factory QuotationWarningDto.fromJson(DataMap json) => QuotationWarningDto(
        code: json['code'] as String? ?? '',
        lineId: json['lineId'] as String? ?? '',
      );
}
