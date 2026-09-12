import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_draft.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/create_customer.dart';

part 'add_customer_event.dart';
part 'add_customer_state.dart';

/// Registers a new shop against `POST /api/v1/mobile/customers`.
///
/// This used to be a three-step form that ended in a two-second delay and a
/// success screen — nothing was ever sent. It also required the rep to pick a
/// *won lead* first, so a shop that had never been in the pipeline could not be
/// added at all. Both are gone: the form submits directly.
///
/// The created customer lands in `Draft` and cannot trade until someone
/// holding `customers.approve` activates it, so success here means "registered
/// and awaiting approval", not "ready to sell to".
class AddCustomerBloc extends Bloc<AddCustomerEvent, AddCustomerState> {
  AddCustomerBloc({required CreateCustomer createCustomer})
      : _createCustomer = createCustomer,
        super(AddCustomerState()) {
    on<UpdateShopDetails>((event, emit) {
      emit(state.copyWith(
        customerCode: event.customerCode,
        shopName: event.shopName,
        shopType: event.shopType,
        ownerName: event.ownerName,
        addressLine1: event.addressLine1,
        city: event.city,
      ));
    });

    on<UpdateContactDetails>((event, emit) {
      emit(state.copyWith(
        contactName: event.name,
        contactRole: event.role,
        contactPhone: event.phone,
      ));
    });

    on<UpdateLocationAndPapers>((event, emit) {
      emit(state.copyWith(
        gpsLocation: event.gpsLocation,
        latitude: () => event.latitude,
        longitude: () => event.longitude,
        businessLicencePath: event.businessLicencePath,
        taxPaperPath: event.taxPaperPath,
      ));
    });

    on<NextStep>((event, emit) {
      if (state.currentStep == CustomerFormStep.shopDetails) {
        emit(state.copyWith(currentStep: CustomerFormStep.contactPerson));
      } else if (state.currentStep == CustomerFormStep.contactPerson) {
        emit(state.copyWith(currentStep: CustomerFormStep.locationAndPapers));
      }
    });

    on<PreviousStep>((event, emit) {
      if (state.currentStep == CustomerFormStep.locationAndPapers) {
        emit(state.copyWith(currentStep: CustomerFormStep.contactPerson));
      } else if (state.currentStep == CustomerFormStep.contactPerson) {
        emit(state.copyWith(currentStep: CustomerFormStep.shopDetails));
      }
    });

    on<SubmitToHQ>((event, emit) async {
      emit(state.copyWith(
        status: AddCustomerStatus.submitting,
        errorMessage: () => null,
      ));

      final result = await _createCustomer(state.toDraft());

      result.when(
        success: (_) => emit(state.copyWith(status: AddCustomerStatus.success)),
        // The message is server-supplied and already localised against the
        // `Accept-Language` header, so it is safe to show. A duplicate code
        // (`Customer.DuplicateCode`) and a failed GPS fix
        // (`Customer.CoordinatesMissing`) both arrive here with copy written
        // for the user.
        failure: (f) => emit(state.copyWith(
          status: AddCustomerStatus.failure,
          errorMessage: () => f.message,
        )),
      );
    });
  }

  final CreateCustomer _createCustomer;
}
