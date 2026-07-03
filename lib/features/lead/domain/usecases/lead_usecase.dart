/// Lightweight per-operation wrapper around [LeadRepository] calls.
///
/// Deliberately not the app-wide `UseCase<Type, Params>` (core/usecase) —
/// that contract returns `ResultFuture<Type>` tied to `Success`/`Failed`/
/// `Failure`, which models a real API's error modes. This feature's
/// repository is an in-memory mock that never actually fails, so these
/// usecases just return a plain `Future<Type>` and let the Bloc/Cubit keep
/// their existing try/catch — same error-handling shape as before, just
/// with each operation named and testable in isolation.
abstract class LeadUseCase<Type, Params> {
  const LeadUseCase();
  Future<Type> call(Params params);
}

/// For usecases that take no arguments.
class NoParams {
  const NoParams();
}
