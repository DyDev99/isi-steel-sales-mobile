part of 'add_customer_bloc.dart';

sealed class AddCustomerEvent {}

class UpdateShopDetails extends AddCustomerEvent {
  final String shopName;
  final String shopType;
  final String ownerName;
  UpdateShopDetails(
      {required this.shopName,
      required this.shopType,
      required this.ownerName});
}

class UpdateContactDetails extends AddCustomerEvent {
  final String name;
  final String role;
  final String phone;
  UpdateContactDetails(
      {required this.name, required this.role, required this.phone});
}

class UpdateLocationAndPapers extends AddCustomerEvent {
  final String gpsLocation;
  final String businessLicencePath;
  final String taxPaperPath;
  UpdateLocationAndPapers(
      {required this.gpsLocation,
      required this.businessLicencePath,
      required this.taxPaperPath});
}

class NextStep extends AddCustomerEvent {}

class PreviousStep extends AddCustomerEvent {}

class SubmitToHQ extends AddCustomerEvent {}
