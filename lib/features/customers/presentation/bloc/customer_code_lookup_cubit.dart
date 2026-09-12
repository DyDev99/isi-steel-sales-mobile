import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_code_lookup.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/portal_customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/lookup_customer_by_code.dart';

/// Resolves a customer number the local book does not have.
///
/// Its own cubit rather than an event on `CustomersBloc` because it is the one
/// customer read that leaves the device. Keeping it separate makes that obvious
/// at the call site and keeps the browse path — which must stay local and free
/// — unable to trigger it by accident.
sealed class CustomerCodeLookupState extends Equatable {
  const CustomerCodeLookupState();
  @override
  List<Object?> get props => const [];
}

final class CodeLookupIdle extends CustomerCodeLookupState {
  const CodeLookupIdle();
}

final class CodeLookupInProgress extends CustomerCodeLookupState {
  const CodeLookupInProgress(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

/// Found. [customer] carries the platform `id`, which is what the mobile detail
/// endpoint takes — so the caller can open the customer immediately.
final class CodeLookupFound extends CustomerCodeLookupState {
  const CodeLookupFound(this.customer);
  final PortalCustomer customer;
  @override
  List<Object?> get props => [customer];
}

/// Neither the platform nor SAP has this code. **The only state in which
/// offering to register the shop is safe.**
final class CodeLookupAbsent extends CustomerCodeLookupState {
  const CodeLookupAbsent(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

/// The ERP could not be reached. Distinct from [CodeLookupAbsent] on purpose:
/// the customer may well exist, and inviting a registration here would create a
/// duplicate business partner in SAP.
final class CodeLookupUnavailable extends CustomerCodeLookupState {
  const CodeLookupUnavailable();
}

/// A transport or authorisation failure — not an answer about the code.
final class CodeLookupFailed extends CustomerCodeLookupState {
  const CodeLookupFailed(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class CustomerCodeLookupCubit extends Cubit<CustomerCodeLookupState> {
  CustomerCodeLookupCubit(this._lookup) : super(const CodeLookupIdle());

  final LookupCustomerByCode _lookup;

  /// Looks [code] up on the server.
  ///
  /// Only ever called from an explicit action on a full code — never from the
  /// keystroke path, because this can reach the ERP.
  Future<void> lookup(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    emit(CodeLookupInProgress(trimmed));
    final result = await _lookup(trimmed);

    emit(result.when(
      success: (outcome) => switch (outcome) {
        CustomerCodeFound(:final customer) => CodeLookupFound(customer),
        CustomerCodeAbsent() => CodeLookupAbsent(trimmed),
        CustomerCodeUnavailable() => const CodeLookupUnavailable(),
      },
      failure: (failure) => CodeLookupFailed(failure.message),
    ));
  }

  void reset() => emit(const CodeLookupIdle());
}

/// Whether [query] is worth spending a server round trip on.
///
/// A customer number, not a name fragment. SAP numbers are ten digits
/// (`6100000017`) and platform codes look like `BP-202608-00002` or
/// `ISI-PP0005`, so this asks for something code-shaped and long enough to be
/// unambiguous — a rep typing a shop name must never trigger a call that can
/// reach the ERP.
bool looksLikeCustomerCode(String query) {
  final trimmed = query.trim();
  if (trimmed.length < 6) return false;
  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9\-_/]*$').hasMatch(trimmed) &&
      RegExp(r'\d').hasMatch(trimmed);
}
