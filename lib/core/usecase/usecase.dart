import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';

/// Every use case is a single-responsibility callable object.
abstract class UseCase<Type, Params> {
  const UseCase();
  ResultFuture<Type> call(Params params);
}

/// For use cases that take no arguments.
final class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => const [];
}
