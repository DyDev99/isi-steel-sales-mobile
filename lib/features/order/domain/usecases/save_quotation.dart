import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/quotation_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class SaveQuotation extends UseCase<Quotation, SaveQuotationParams> {
  const SaveQuotation(this._repository);
  final QuotationRepository _repository;

  @override
  ResultFuture<Quotation> call(SaveQuotationParams params) => _repository.saveQuotation(
        items: params.items,
        customerId: params.customerId,
        shopName: params.shopName,
        leadId: params.leadId,
        leadDisplayName: params.leadDisplayName,
        offVisitReason: params.offVisitReason,
        gpsLat: params.gpsLat,
        gpsLng: params.gpsLng,
      );
}
