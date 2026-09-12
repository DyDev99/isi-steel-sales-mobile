import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_api_entities.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/quotation_api_usecases.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/quotation/quotation_builder_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/quotation/quotation_builder_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockOpenQuotation extends Mock implements OpenQuotation {}
class _MockGetQuotationDetail extends Mock implements GetQuotationDetail {}
class _MockUpdateQuotationHeader extends Mock implements UpdateQuotationHeader {}
class _MockAddQuotationLine extends Mock implements AddQuotationLine {}
class _MockUpdateQuotationLine extends Mock implements UpdateQuotationLine {}
class _MockDeleteQuotationLineItem extends Mock implements DeleteQuotationLineItem {}
class _MockSetQuotationDiscounts extends Mock implements SetQuotationDiscounts {}
class _MockGetQuotationPreview extends Mock implements GetQuotationPreview {}
class _MockGetCustomerAgreements extends Mock implements GetCustomerAgreements {}

QuotationDetail _detail(String id, {List<QuotationLineItem> lines = const []}) {
  return QuotationDetail(
    id: id,
    number: 'QT-$id',
    customerId: 'cust-10',
    customerName: 'Customer Ten',
    status: 'Draft',
    statusGroup: QuotationStatusGroup.drafts,
    shipmentType: 'Pickup',
    currency: 'US3',
    revision: 1,
    requiredApprovalLevel: 0,
    lines: lines,
    totals: const QuotationTotals(
      currency: 'US3',
      gross: 0.0,
      discountTotal: 0.0,
      net: 0.0,
      isEstimate: false,
    ),
    createdAt: DateTime(2026, 9, 12),
  );
}

void main() {
  late _MockOpenQuotation mockOpen;
  late _MockGetQuotationDetail mockGetDetail;
  late _MockUpdateQuotationHeader mockUpdateHeader;
  late _MockAddQuotationLine mockAddLine;
  late _MockUpdateQuotationLine mockUpdateLine;
  late _MockDeleteQuotationLineItem mockDeleteLine;
  late _MockSetQuotationDiscounts mockSetDiscounts;
  late _MockGetQuotationPreview mockGetPreview;
  late _MockGetCustomerAgreements mockGetAgreements;

  setUpAll(() {
    registerFallbackValue(const OpenQuotationParams(customerId: 'cust'));
    registerFallbackValue(const CustomerAgreementsParams('cust'));
    registerFallbackValue(const QuotationIdParams('qt'));
    registerFallbackValue(const AddQuotationLineParams(
      id: 'qt',
      materialNumber: 'mat',
      quantity: 1,
    ));
    registerFallbackValue(const SetQuotationDiscountsParams(
      id: 'qt',
      lines: [],
    ));
  });

  setUp(() {
    mockOpen = _MockOpenQuotation();
    mockGetDetail = _MockGetQuotationDetail();
    mockUpdateHeader = _MockUpdateQuotationHeader();
    mockAddLine = _MockAddQuotationLine();
    mockUpdateLine = _MockUpdateQuotationLine();
    mockDeleteLine = _MockDeleteQuotationLineItem();
    mockSetDiscounts = _MockSetQuotationDiscounts();
    mockGetPreview = _MockGetQuotationPreview();
    mockGetAgreements = _MockGetCustomerAgreements();
  });

  QuotationBuilderCubit build() => QuotationBuilderCubit(
        openQuotation: mockOpen,
        getQuotationDetail: mockGetDetail,
        updateQuotationHeader: mockUpdateHeader,
        addQuotationLine: mockAddLine,
        updateQuotationLine: mockUpdateLine,
        deleteQuotationLineItem: mockDeleteLine,
        setQuotationDiscounts: mockSetDiscounts,
        getQuotationPreview: mockGetPreview,
        getCustomerAgreements: mockGetAgreements,
      );

  group('QuotationBuilderCubit', () {
    blocTest<QuotationBuilderCubit, QuotationBuilderState>(
      'initializes by fetching customer agreements and opening quotation',
      build: () {
        when(() => mockGetAgreements(any())).thenAnswer(
          (_) async => const Success([
            CustomerAgreement(
              id: 'agr-1',
              category: 'Roofing',
              percent: 2.5,
              kind: 'StandingDiscount',
              status: 'Active',
            ),
          ]),
        );
        when(() => mockOpen(any())).thenAnswer(
          (_) async => Success(_detail('qt-new')),
        );
        return build();
      },
      act: (cubit) => cubit.initialize(customerId: 'cust-10'),
      expect: () => [
        const QuotationBuilderLoading(),
        isA<QuotationBuilderReady>()
            .having((s) => s.quotation.id, 'id', 'qt-new')
            .having((s) => s.agreements.length, 'agreements length', 1)
            .having((s) => s.agreements.first.category, 'category', 'Roofing'),
      ],
    );

    blocTest<QuotationBuilderCubit, QuotationBuilderState>(
      'addLine updates quotation lines',
      build: () {
        when(() => mockAddLine(any())).thenAnswer(
          (_) async => Success(_detail('qt-new', lines: [
            const QuotationLineItem(
              id: 'line-1',
              lineNumber: 10,
              materialNumber: 'MAT-99',
              materialDescription: 'Pipe 2 inch',
              quantity: 10,
              unit: 'PC',
              priceAmount: 12.0,
              priceCurrency: 'US3',
              pricePricingUnit: 1,
              priceConditionUnit: 'PC',
              discounts: [],
              gross: 120.0,
              discountTotal: 0.0,
              net: 120.0,
            ),
          ])),
        );
        return build();
      },
      seed: () => QuotationBuilderReady(quotation: _detail('qt-new')),
      act: (cubit) => cubit.addLine(materialNumber: 'MAT-99', quantity: 10),
      expect: () => [
        isA<QuotationBuilderReady>()
            .having((s) => s.isMutating, 'isMutating true', true),
        isA<QuotationBuilderReady>()
            .having((s) => s.isMutating, 'isMutating false', false)
            .having((s) => s.quotation.lines.length, 'lines count', 1),
      ],
    );

    blocTest<QuotationBuilderCubit, QuotationBuilderState>(
      'setDiscounts updates discounts and emits ready state',
      build: () {
        when(() => mockSetDiscounts(any())).thenAnswer(
          (_) async => Success(_detail('qt-new')),
        );
        return build();
      },
      seed: () => QuotationBuilderReady(quotation: _detail('qt-new')),
      act: (cubit) => cubit.setDiscounts([
        const QuotationDiscountIntent(lineId: 'line-1', percent: 5.0),
      ]),
      expect: () => [
        isA<QuotationBuilderReady>()
            .having((s) => s.isMutating, 'isMutating true', true),
        isA<QuotationBuilderReady>()
            .having((s) => s.isMutating, 'isMutating false', false),
      ],
    );
  });
}
