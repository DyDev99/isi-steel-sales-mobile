import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/paged_result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_api_entities.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/quotation_api_repository.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/promotions/promo_view.dart';

class GetQuotationsParams extends Equatable {
  const GetQuotationsParams({
    this.status,
    this.customerId,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? status;
  final String? customerId;
  final int page;
  final int pageSize;

  @override
  List<Object?> get props => [status, customerId, page, pageSize];
}

class GetQuotationsList
    implements UseCase<PagedResult<QuotationSummary>, GetQuotationsParams> {
  const GetQuotationsList(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<PagedResult<QuotationSummary>> call(GetQuotationsParams params) {
    return _repository.getQuotations(
      status: params.status,
      customerId: params.customerId,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class OpenQuotationParams extends Equatable {
  const OpenQuotationParams({
    required this.customerId,
    this.shipmentType = 'Pickup',
    this.shipTo,
  });

  final String customerId;
  final String shipmentType;
  final String? shipTo;

  @override
  List<Object?> get props => [customerId, shipmentType, shipTo];
}

class OpenQuotation
    implements UseCase<QuotationDetail, OpenQuotationParams> {
  const OpenQuotation(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(OpenQuotationParams params) {
    return _repository.createQuotation(
      customerId: params.customerId,
      shipmentType: params.shipmentType,
      shipTo: params.shipTo,
    );
  }
}

class QuotationIdParams extends Equatable {
  const QuotationIdParams(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class GetQuotationDetail
    implements UseCase<QuotationDetail, QuotationIdParams> {
  const GetQuotationDetail(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(QuotationIdParams params) {
    return _repository.getQuotationDetail(params.id);
  }
}

class UpdateQuotationHeaderParams extends Equatable {
  const UpdateQuotationHeaderParams({
    required this.id,
    required this.shipmentType,
    this.shipTo,
    this.paymentTerm,
    this.customerReference,
    this.remarks,
  });

  final String id;
  final String shipmentType;
  final String? shipTo;
  final String? paymentTerm;
  final String? customerReference;
  final String? remarks;

  @override
  List<Object?> get props =>
      [id, shipmentType, shipTo, paymentTerm, customerReference, remarks];
}

class UpdateQuotationHeader
    implements UseCase<QuotationDetail, UpdateQuotationHeaderParams> {
  const UpdateQuotationHeader(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(UpdateQuotationHeaderParams params) {
    return _repository.updateQuotationHeader(
      params.id,
      shipmentType: params.shipmentType,
      shipTo: params.shipTo,
      paymentTerm: params.paymentTerm,
      customerReference: params.customerReference,
      remarks: params.remarks,
    );
  }
}

class AddQuotationLineParams extends Equatable {
  const AddQuotationLineParams({
    required this.id,
    required this.materialNumber,
    required this.quantity,
    this.unit,
  });

  final String id;
  final String materialNumber;
  final double quantity;
  final String? unit;

  @override
  List<Object?> get props => [id, materialNumber, quantity, unit];
}

class AddQuotationLine
    implements UseCase<QuotationDetail, AddQuotationLineParams> {
  const AddQuotationLine(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(AddQuotationLineParams params) {
    return _repository.addLine(
      params.id,
      materialNumber: params.materialNumber,
      quantity: params.quantity,
      unit: params.unit,
    );
  }
}

class UpdateQuotationLineParams extends Equatable {
  const UpdateQuotationLineParams({
    required this.id,
    required this.lineId,
    required this.quantity,
    this.unit,
  });

  final String id;
  final String lineId;
  final double quantity;
  final String? unit;

  @override
  List<Object?> get props => [id, lineId, quantity, unit];
}

class UpdateQuotationLine
    implements UseCase<QuotationDetail, UpdateQuotationLineParams> {
  const UpdateQuotationLine(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(UpdateQuotationLineParams params) {
    return _repository.updateLine(
      params.id,
      params.lineId,
      quantity: params.quantity,
      unit: params.unit,
    );
  }
}

class DeleteQuotationLineParams extends Equatable {
  const DeleteQuotationLineParams({
    required this.id,
    required this.lineId,
  });

  final String id;
  final String lineId;

  @override
  List<Object?> get props => [id, lineId];
}

class DeleteQuotationLineItem
    implements UseCase<QuotationDetail, DeleteQuotationLineParams> {
  const DeleteQuotationLineItem(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(DeleteQuotationLineParams params) {
    return _repository.deleteLine(params.id, params.lineId);
  }
}

class SetQuotationDiscountsParams extends Equatable {
  const SetQuotationDiscountsParams({
    required this.id,
    required this.lines,
  });

  final String id;
  final List<QuotationDiscountIntent> lines;

  @override
  List<Object?> get props => [id, lines];
}

class SetQuotationDiscounts
    implements UseCase<QuotationDetail, SetQuotationDiscountsParams> {
  const SetQuotationDiscounts(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(SetQuotationDiscountsParams params) {
    return _repository.setDiscounts(params.id, lines: params.lines);
  }
}

class GetQuotationPreview
    implements UseCase<QuotationPreviewData, QuotationIdParams> {
  const GetQuotationPreview(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationPreviewData> call(QuotationIdParams params) {
    return _repository.getPreview(params.id);
  }
}

class RepriceQuotation
    implements UseCase<QuotationDetail, QuotationIdParams> {
  const RepriceQuotation(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(QuotationIdParams params) {
    return _repository.reprice(params.id);
  }
}

class SubmitQuotation
    implements UseCase<QuotationDetail, QuotationIdParams> {
  const SubmitQuotation(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(QuotationIdParams params) {
    return _repository.submit(params.id);
  }
}

class CancelQuotation
    implements UseCase<QuotationDetail, QuotationIdParams> {
  const CancelQuotation(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<QuotationDetail> call(QuotationIdParams params) {
    return _repository.cancel(params.id);
  }
}

class GetQuotationHistory
    implements UseCase<List<QuotationApprovalHistory>, QuotationIdParams> {
  const GetQuotationHistory(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<List<QuotationApprovalHistory>> call(QuotationIdParams params) {
    return _repository.getHistory(params.id);
  }
}

class CustomerAgreementsParams extends Equatable {
  const CustomerAgreementsParams(this.customerId);
  final String customerId;

  @override
  List<Object?> get props => [customerId];
}

class GetCustomerAgreements
    implements UseCase<List<CustomerAgreement>, CustomerAgreementsParams> {
  const GetCustomerAgreements(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<List<CustomerAgreement>> call(CustomerAgreementsParams params) {
    return _repository.getCustomerAgreements(params.customerId);
  }
}

class CustomerIncentivesParams extends Equatable {
  const CustomerIncentivesParams({
    required this.customerId,
    this.shipment,
  });

  final String customerId;
  final String? shipment;

  @override
  List<Object?> get props => [customerId, shipment];
}

class GetCustomerIncentives
    implements UseCase<List<PromoGroup>, CustomerIncentivesParams> {
  const GetCustomerIncentives(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<List<PromoGroup>> call(CustomerIncentivesParams params) {
    return _repository.getCustomerIncentives(
      params.customerId,
      shipment: params.shipment,
    );
  }
}

class CustomerPromotionsParams extends Equatable {
  const CustomerPromotionsParams(this.customerId);
  final String customerId;

  @override
  List<Object?> get props => [customerId];
}

class GetCustomerPromotions
    implements UseCase<List<PromoView>, CustomerPromotionsParams> {
  const GetCustomerPromotions(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<List<PromoView>> call(CustomerPromotionsParams params) {
    return _repository.getCustomerPromotions(params.customerId);
  }
}

class GetDiscountAuthority
    implements UseCase<DiscountAuthority, NoParams> {
  const GetDiscountAuthority(this._repository);
  final QuotationApiRepository _repository;

  @override
  ResultFuture<DiscountAuthority> call([NoParams params = const NoParams()]) {
    return _repository.getDiscountAuthority();
  }
}
