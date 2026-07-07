import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/repositories/revenue_repository.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_products.dart';
import 'package:mocktail/mocktail.dart';

class _MockRevenueRepository extends Mock implements RevenueRepository {}

void main() {
  late _MockRevenueRepository repository;
  late GetProducts usecase;

  setUp(() {
    repository = _MockRevenueRepository();
    usecase = GetProducts(repository);
  });

  const tProducts = [
    Product(
      id: 'p1',
      name: 'Rebar 12mm',
      sku: 'RB-12',
      categoryId: 'cat-rebar',
      unit: 'Ton',
      unitPrice: 100,
      availableStock: 5,
    ),
  ];

  test('forwards the repository Success payload unchanged', () async {
    when(() => repository.getProducts()).thenAnswer((_) async => const Success(tProducts));

    final result = await usecase(const NoParams());

    expect(result, isA<Success<List<Product>>>());
    expect((result as Success).data, tProducts);
    verify(() => repository.getProducts()).called(1);
  });

  test('propagates a repository Failure without swallowing it', () async {
    const failure = CacheFailure(message: 'boom');
    when(() => repository.getProducts()).thenAnswer((_) async => const Failed(failure));

    final result = await usecase(const NoParams());

    expect(result, isA<Failed<List<Product>>>());
    expect((result as Failed).failure, failure);
  });
}
