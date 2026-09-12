import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_api_entities.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/quotation_api_usecases.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/quotation/quotation_builder_state.dart';

class QuotationBuilderCubit extends Cubit<QuotationBuilderState> {
  QuotationBuilderCubit({
    required OpenQuotation openQuotation,
    required GetQuotationDetail getQuotationDetail,
    required UpdateQuotationHeader updateQuotationHeader,
    required AddQuotationLine addQuotationLine,
    required UpdateQuotationLine updateQuotationLine,
    required DeleteQuotationLineItem deleteQuotationLineItem,
    required SetQuotationDiscounts setQuotationDiscounts,
    required GetQuotationPreview getQuotationPreview,
    required GetCustomerAgreements getCustomerAgreements,
    GetDiscountAuthority? getDiscountAuthority,
  })  : _openQuotation = openQuotation,
        _getQuotationDetail = getQuotationDetail,
        _updateQuotationHeader = updateQuotationHeader,
        _addQuotationLine = addQuotationLine,
        _updateQuotationLine = updateQuotationLine,
        _deleteQuotationLineItem = deleteQuotationLineItem,
        _setQuotationDiscounts = setQuotationDiscounts,
        _getQuotationPreview = getQuotationPreview,
        _getCustomerAgreements = getCustomerAgreements,
        _getDiscountAuthority = getDiscountAuthority,
        super(const QuotationBuilderInitial());

  final OpenQuotation _openQuotation;
  final GetQuotationDetail _getQuotationDetail;
  final UpdateQuotationHeader _updateQuotationHeader;
  final AddQuotationLine _addQuotationLine;
  final UpdateQuotationLine _updateQuotationLine;
  final DeleteQuotationLineItem _deleteQuotationLineItem;
  final SetQuotationDiscounts _setQuotationDiscounts;
  final GetQuotationPreview _getQuotationPreview;
  final GetCustomerAgreements _getCustomerAgreements;
  final GetDiscountAuthority? _getDiscountAuthority;

  Timer? _debounceTimer;
  static const _previewDebounce = Duration(milliseconds: 300);

  Future<void> initialize({
    required String customerId,
    String? existingQuotationId,
    String shipmentType = 'Pickup',
    String? shipTo,
  }) async {
    emit(const QuotationBuilderLoading());

    // Load customer agreements & discount authority concurrently
    final agreementsFuture =
        _getCustomerAgreements(CustomerAgreementsParams(customerId));
    final authorityFuture = _getDiscountAuthority?.call();

    final agreementsResult = await agreementsFuture;
    final agreements = agreementsResult.when(
      success: (ag) => ag,
      failure: (_) => const <CustomerAgreement>[],
    );

    DiscountAuthority? discountAuthority;
    if (authorityFuture != null) {
      final authorityResult = await authorityFuture;
      discountAuthority = authorityResult.when(
        success: (auth) => auth,
        failure: (_) => null,
      );
    }

    if (existingQuotationId != null && existingQuotationId.isNotEmpty) {
      final detailResult =
          await _getQuotationDetail(QuotationIdParams(existingQuotationId));
      await detailResult.when(
        success: (detail) async {
          emit(QuotationBuilderReady(
            quotation: detail,
            agreements: agreements,
            discountAuthority: discountAuthority,
          ));
          if (detail.lines.isNotEmpty) {
            await refreshPreview();
          }
        },
        failure: (failure) {
          emit(QuotationBuilderError(failure.message));
        },
      );
    } else {
      final openResult = await _openQuotation(OpenQuotationParams(
        customerId: customerId,
        shipmentType: shipmentType,
        shipTo: shipTo,
      ));

      openResult.when(
        success: (detail) {
          emit(QuotationBuilderReady(
            quotation: detail,
            agreements: agreements,
            discountAuthority: discountAuthority,
          ));
        },
        failure: (failure) {
          emit(QuotationBuilderError(failure.message));
        },
      );
    }
  }

  Future<void> updateHeader({
    required String shipmentType,
    String? shipTo,
    String? paymentTerm,
    String? customerReference,
    String? remarks,
  }) async {
    final current = state;
    if (current is! QuotationBuilderReady) return;

    emit(current.copyWith(isMutating: true, errorMessage: () => null));

    final result = await _updateQuotationHeader(UpdateQuotationHeaderParams(
      id: current.quotation.id,
      shipmentType: shipmentType,
      shipTo: shipTo,
      paymentTerm: paymentTerm,
      customerReference: customerReference,
      remarks: remarks,
    ));

    result.when(
      success: (updated) {
        emit(current.copyWith(quotation: updated, isMutating: false));
      },
      failure: (failure) {
        emit(current.copyWith(
          isMutating: false,
          errorMessage: () => failure.message,
        ));
      },
    );
  }

  Future<void> addLine({
    required String materialNumber,
    required double quantity,
    String? unit,
  }) async {
    final current = state;
    if (current is! QuotationBuilderReady) return;

    emit(current.copyWith(isMutating: true, errorMessage: () => null));

    final result = await _addQuotationLine(AddQuotationLineParams(
      id: current.quotation.id,
      materialNumber: materialNumber,
      quantity: quantity,
      unit: unit,
    ));

    result.when(
      success: (updated) {
        emit(current.copyWith(quotation: updated, isMutating: false));
        _schedulePreview();
      },
      failure: (failure) {
        emit(current.copyWith(
          isMutating: false,
          errorMessage: () => failure.message,
        ));
      },
    );
  }

  Future<void> updateLineQuantity({
    required String lineId,
    required double quantity,
    String? unit,
  }) async {
    final current = state;
    if (current is! QuotationBuilderReady) return;

    emit(current.copyWith(isMutating: true, errorMessage: () => null));

    final result = await _updateQuotationLine(UpdateQuotationLineParams(
      id: current.quotation.id,
      lineId: lineId,
      quantity: quantity,
      unit: unit,
    ));

    result.when(
      success: (updated) {
        emit(current.copyWith(quotation: updated, isMutating: false));
        _schedulePreview();
      },
      failure: (failure) {
        emit(current.copyWith(
          isMutating: false,
          errorMessage: () => failure.message,
        ));
      },
    );
  }

  Future<void> deleteLine(String lineId) async {
    final current = state;
    if (current is! QuotationBuilderReady) return;

    emit(current.copyWith(isMutating: true, errorMessage: () => null));

    final result = await _deleteQuotationLineItem(DeleteQuotationLineParams(
      id: current.quotation.id,
      lineId: lineId,
    ));

    result.when(
      success: (updated) {
        emit(current.copyWith(quotation: updated, isMutating: false));
        if (updated.lines.isNotEmpty) {
          _schedulePreview();
        } else {
          emit(current.copyWith(
            quotation: updated,
            preview: () => null,
            isMutating: false,
          ));
        }
      },
      failure: (failure) {
        emit(current.copyWith(
          isMutating: false,
          errorMessage: () => failure.message,
        ));
      },
    );
  }

  Future<void> setDiscounts(List<QuotationDiscountIntent> lines) async {
    final current = state;
    if (current is! QuotationBuilderReady) return;

    emit(current.copyWith(isMutating: true, errorMessage: () => null));

    final result = await _setQuotationDiscounts(SetQuotationDiscountsParams(
      id: current.quotation.id,
      lines: lines,
    ));

    result.when(
      success: (updated) {
        emit(current.copyWith(quotation: updated, isMutating: false));
        _schedulePreview();
      },
      failure: (failure) {
        emit(current.copyWith(
          isMutating: false,
          errorMessage: () => failure.message,
        ));
      },
    );
  }

  void _schedulePreview() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_previewDebounce, () {
      unawaited(refreshPreview());
    });
  }

  Future<void> refreshPreview() async {
    final current = state;
    if (current is! QuotationBuilderReady) return;

    emit(current.copyWith(isDebouncingPreview: true));

    final result =
        await _getQuotationPreview(QuotationIdParams(current.quotation.id));

    result.when(
      success: (previewData) {
        final now = state;
        if (now is QuotationBuilderReady) {
          emit(now.copyWith(
            preview: () => previewData,
            isDebouncingPreview: false,
          ));
        }
      },
      failure: (failure) {
        final now = state;
        if (now is QuotationBuilderReady) {
          emit(now.copyWith(
            isDebouncingPreview: false,
            errorMessage: () => failure.message,
          ));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
