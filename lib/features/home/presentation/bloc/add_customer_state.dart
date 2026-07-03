part of 'add_customer_bloc.dart';

enum CustomerFormStep { shopDetails, contactPerson, locationAndPapers }
enum AddCustomerStatus { initial, filling, submitting, success, failure }

class AddCustomerState {
  final CustomerFormStep currentStep;
  final AddCustomerStatus status;
  final String shopName;
  final String shopType;
  final String ownerName;
  final String contactName;
  final String contactRole;
  final String contactPhone;
  final String gpsLocation;
  final String businessLicencePath;
  final String taxPaperPath;

  AddCustomerState({
    this.currentStep = CustomerFormStep.shopDetails,
    this.status = AddCustomerStatus.initial,
    this.shopName = '',
    this.shopType = '',
    this.ownerName = '',
    this.contactName = '',
    this.contactRole = '',
    this.contactPhone = '',
    this.gpsLocation = '',
    this.businessLicencePath = '',
    this.taxPaperPath = '',
  });

  AddCustomerState copyWith({
    CustomerFormStep? currentStep,
    AddCustomerStatus? status,
    String? shopName,
    String? shopType,
    String? ownerName,
    String? contactName,
    String? contactRole,
    String? contactPhone,
    String? gpsLocation,
    String? businessLicencePath,
    String? taxPaperPath,
  }) {
    return AddCustomerState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      shopName: shopName ?? this.shopName,
      shopType: shopType ?? this.shopType,
      ownerName: ownerName ?? this.ownerName,
      contactName: contactName ?? this.contactName,
      contactRole: contactRole ?? this.contactRole,
      contactPhone: contactPhone ?? this.contactPhone,
      gpsLocation: gpsLocation ?? this.gpsLocation,
      businessLicencePath: businessLicencePath ?? this.businessLicencePath,
      taxPaperPath: taxPaperPath ?? this.taxPaperPath,
    );
  }
}