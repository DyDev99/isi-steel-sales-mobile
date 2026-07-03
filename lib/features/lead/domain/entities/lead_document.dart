import 'package:equatable/equatable.dart';

enum DocumentType { businessLicense, taxRegistration, ownerId, storefrontPhoto, warehousePhoto, other }

class LeadDocument extends Equatable {
  const LeadDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.uploadedDate,
  });

  final String id;
  final String name;
  final DocumentType type;
  final String url;
  final DateTime uploadedDate;

  @override
  List<Object?> get props => [id, name, type, url, uploadedDate];
}
