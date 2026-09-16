import 'package:isi_steel_sales_mobile/features/quotations/data/datasources/quotation_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/quotations/data/models/quotation_dto.dart';
import 'package:isi_steel_sales_mobile/features/quotations/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/quotations/domain/repositories/quotation_repository.dart';

class QuotationRepositoryImpl implements QuotationRepository {
  const QuotationRepositoryImpl(this._remoteDataSource);

  final QuotationRemoteDataSource _remoteDataSource;

  Quotation _mapDtoToEntity(QuotationDto dto) {
    return Quotation(
      id: dto.id,
      number: dto.number,
      depotId: dto.depotId,
      depotName: dto.depotName,
      status: dto.status,
      statusGroup: dto.statusGroup,
      currency: dto.currency,
      net: dto.net,
      lineCount: dto.lineCount,
      validTo: dto.validTo,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      statusDisplay: dto.statusDisplay,
    );
  }

  QuotationDetail _mapDetailDtoToEntity(QuotationDetailDto dto) {
    return QuotationDetail(
      id: dto.id,
      number: dto.number,
      depotId: dto.depotId,
      depotName: dto.depotName,
      status: dto.status,
      statusGroup: dto.statusGroup,
      currency: dto.currency,
      net: dto.net,
      lineCount: dto.lineCount,
      validTo: dto.validTo,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      statusDisplay: dto.statusDisplay,
      shipmentType: dto.shipmentType,
      shipTo: dto.shipTo,
      paymentTerm: dto.paymentTerm,
      depotReference: dto.depotReference,
      remarks: dto.remarks,
      manualDiscountLimitPercent: dto.manualDiscountLimitPercent,
      lineDiscountCapPercent: dto.lineDiscountCapPercent,
      requiredApprovalLevel: dto.requiredApprovalLevel,
      revision: dto.revision,
      decisionReason: dto.decisionReason,
      lines: dto.lines
          .map((l) => QuotationLine(
                lineId: l.lineId,
                materialNumber: l.materialNumber,
                materialDescription: l.materialDescription,
                quantity: l.quantity,
                unit: l.unit,
                priceAmount: l.priceAmount,
                priceCurrency: l.priceCurrency,
                pricePricingUnit: l.pricePricingUnit,
                priceConditionUnit: l.priceConditionUnit,
                gross: l.gross,
                discountTotal: l.discountTotal,
                net: l.net,
                discounts: l.discounts
                    .map((d) => QuotationDiscount(
                          kind: d.kind,
                          percent: d.percent,
                          reason: d.reason,
                          amount: d.amount,
                        ))
                    .toList(),
              ))
          .toList(),
      totals: dto.totals != null
          ? QuotationTotals(
              currency: dto.totals!.currency,
              gross: dto.totals!.gross,
              discountTotal: dto.totals!.discountTotal,
              net: dto.totals!.net,
              isEstimate: dto.totals!.isEstimate,
              tax: dto.totals!.tax,
            )
          : null,
      warnings: dto.warnings
          .map((w) => QuotationWarning(
                code: w.code,
                lineId: w.lineId,
              ))
          .toList(),
    );
  }

  @override
  Future<List<Quotation>> getQuotations({
    String? status,
    String? depotId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final list = await _remoteDataSource.getQuotations(
      status: status,
      depotId: depotId,
      page: page,
      pageSize: pageSize,
    );
    return list.map(_mapDtoToEntity).toList();
  }

  @override
  Future<String> createQuotation({
    required String depotId,
    String shipmentType = 'Pickup',
    String? shipTo,
  }) {
    return _remoteDataSource.createQuotation(
      depotId: depotId,
      shipmentType: shipmentType,
      shipTo: shipTo,
    );
  }

  @override
  Future<QuotationDetail> getQuotationDetail(String id) async {
    final detail = await _remoteDataSource.getQuotationDetail(id);
    return _mapDetailDtoToEntity(detail);
  }

  @override
  Future<QuotationDetail> updateQuotationHeader(
    String id, {
    required String shipmentType,
    String? shipTo,
    String? paymentTerm,
    String? depotReference,
    String? remarks,
  }) async {
    final detail = await _remoteDataSource.updateQuotationHeader(
      id,
      shipmentType: shipmentType,
      shipTo: shipTo,
      paymentTerm: paymentTerm,
      depotReference: depotReference,
      remarks: remarks,
    );
    return _mapDetailDtoToEntity(detail);
  }

  @override
  Future<QuotationDetail> addLine(
    String id, {
    required String materialNumber,
    required double quantity,
    String? unit,
  }) async {
    final detail = await _remoteDataSource.addLine(
      id,
      materialNumber: materialNumber,
      quantity: quantity,
      unit: unit,
    );
    return _mapDetailDtoToEntity(detail);
  }

  @override
  Future<QuotationDetail> updateLineQuantity(
    String id,
    String lineId, {
    required double quantity,
  }) async {
    final detail = await _remoteDataSource.updateLineQuantity(
      id,
      lineId,
      quantity: quantity,
    );
    return _mapDetailDtoToEntity(detail);
  }

  @override
  Future<QuotationDetail> removeLine(String id, String lineId) async {
    final detail = await _remoteDataSource.removeLine(id, lineId);
    return _mapDetailDtoToEntity(detail);
  }

  @override
  Future<QuotationDetail> updateDiscounts(
    String id,
    List<Map<String, dynamic>> discounts,
  ) async {
    final detail = await _remoteDataSource.updateDiscounts(id, discounts);
    return _mapDetailDtoToEntity(detail);
  }

  @override
  Future<QuotationDetail> previewQuotation(String id) async {
    final detail = await _remoteDataSource.previewQuotation(id);
    return _mapDetailDtoToEntity(detail);
  }

  @override
  Future<QuotationDetail> repriceQuotation(String id) async {
    final detail = await _remoteDataSource.repriceQuotation(id);
    return _mapDetailDtoToEntity(detail);
  }

  @override
  Future<QuotationDetail> submitQuotation(String id) async {
    final detail = await _remoteDataSource.submitQuotation(id);
    return _mapDetailDtoToEntity(detail);
  }

  @override
  Future<QuotationDetail> cancelQuotation(String id) async {
    final detail = await _remoteDataSource.cancelQuotation(id);
    return _mapDetailDtoToEntity(detail);
  }
}
