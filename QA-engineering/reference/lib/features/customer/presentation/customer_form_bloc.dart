import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/create_customer_usecase.dart';
import '../domain/customer.dart';
import '../domain/customer_repository.dart';
import '../domain/validators.dart';

// ---------- Events ----------
sealed class CustomerFormEvent {
  const CustomerFormEvent();
}

class NameChanged extends CustomerFormEvent {
  const NameChanged(this.value);
  final String value;
}

class PhoneChanged extends CustomerFormEvent {
  const PhoneChanged(this.value);
  final String value;
}

class CreditLimitChanged extends CustomerFormEvent {
  const CreditLimitChanged(this.value);
  final String value;
}

class TypeChanged extends CustomerFormEvent {
  const TypeChanged(this.value);
  final CustomerType value;
}

class FormSubmitted extends CustomerFormEvent {
  const FormSubmitted();
}

// ---------- State ----------
enum FormStatus { editing, submitting, success, failure }

class CustomerFormState extends Equatable {
  const CustomerFormState({
    this.name = '',
    this.phone = '',
    this.creditLimit = '',
    this.type = CustomerType.retail,
    this.status = FormStatus.editing,
    this.showErrors = false,
    this.errorMessage,
  });

  final String name;
  final String phone;
  final String creditLimit;
  final CustomerType type;
  final FormStatus status;
  final bool showErrors;
  final String? errorMessage;

  Map<String, String> get errors {
    final result = <String, String>{};
    final n = CustomerValidators.name(name);
    final p = CustomerValidators.phone(phone);
    final c = CustomerValidators.creditLimit(creditLimit);
    if (n != null) result['name'] = n;
    if (p != null) result['phone'] = p;
    if (c != null) result['creditLimit'] = c;
    return result;
  }

  bool get isValid => errors.isEmpty;

  String? errorFor(String field) => showErrors ? errors[field] : null;

  CustomerFormState copyWith({
    String? name,
    String? phone,
    String? creditLimit,
    CustomerType? type,
    FormStatus? status,
    bool? showErrors,
    String? errorMessage,
  }) =>
      CustomerFormState(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        creditLimit: creditLimit ?? this.creditLimit,
        type: type ?? this.type,
        status: status ?? this.status,
        showErrors: showErrors ?? this.showErrors,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [name, phone, creditLimit, type, status, showErrors, errorMessage];
}

// ---------- Bloc ----------
class CustomerFormBloc extends Bloc<CustomerFormEvent, CustomerFormState> {
  CustomerFormBloc(this._createCustomer) : super(const CustomerFormState()) {
    on<NameChanged>((e, emit) => emit(state.copyWith(name: e.value)));
    on<PhoneChanged>((e, emit) => emit(state.copyWith(phone: e.value)));
    on<CreditLimitChanged>(
        (e, emit) => emit(state.copyWith(creditLimit: e.value)));
    on<TypeChanged>((e, emit) => emit(state.copyWith(type: e.value)));
    on<FormSubmitted>(_onSubmitted);
  }

  final CreateCustomerUseCase _createCustomer;

  Future<void> _onSubmitted(
      FormSubmitted event, Emitter<CustomerFormState> emit) async {
    // Guard against double-tap submit.
    if (state.status == FormStatus.submitting) return;
    if (!state.isValid) {
      emit(state.copyWith(showErrors: true, status: FormStatus.editing));
      return;
    }
    emit(state.copyWith(status: FormStatus.submitting, showErrors: true));
    try {
      await _createCustomer(Customer(
        name: state.name.trim(),
        phone: state.phone.replaceAll(RegExp(r'[\s-]'), ''),
        type: state.type,
        creditLimit: double.parse(state.creditLimit.trim()),
      ));
      emit(state.copyWith(status: FormStatus.success));
    } on NetworkException {
      emit(state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'No internet connection. Please try again.'));
    } on UnauthorizedException {
      emit(state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Your session has expired. Please log in again.'));
    } on ServerException {
      emit(state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Server error. Please try again later.'));
    } on ValidationException {
      emit(state.copyWith(
          status: FormStatus.failure, errorMessage: 'Some fields are invalid.'));
    } catch (_) {
      emit(state.copyWith(
          status: FormStatus.failure, errorMessage: 'Something went wrong.'));
    }
  }
}
