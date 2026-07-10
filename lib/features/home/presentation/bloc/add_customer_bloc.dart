import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_customer_event.dart';
part 'add_customer_state.dart';

class AddCustomerBloc extends Bloc<AddCustomerEvent, AddCustomerState> {
  AddCustomerBloc() : super(AddCustomerState()) {
    on<UpdateShopDetails>((event, emit) {
      emit(state.copyWith(
        shopName: event.shopName,
        shopType: event.shopType,
        ownerName: event.ownerName,
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
      emit(state.copyWith(status: AddCustomerStatus.submitting));
      try {
        // Simulating sending the structural data and raw compliance images to SAP queue
        await Future.delayed(const Duration(seconds: 2));
        emit(state.copyWith(status: AddCustomerStatus.success));
      } catch (_) {
        emit(state.copyWith(status: AddCustomerStatus.failure));
      }
    });
  }
}
