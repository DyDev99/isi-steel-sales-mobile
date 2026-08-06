import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/contact.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/credit_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_source.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';

/// A prospective or existing customer (depot / steel shop / hardware store)
/// as it moves through the sales pipeline. [opportunityInfo] is populated
/// once the lead reaches [PipelineStage.opportunities] or later; [wonInfo]
/// only once it reaches [PipelineStage.won].
class Lead extends Equatable {
  const Lead({
    required this.id,
    required this.companyName,
    this.companyNameKh = '',
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.province,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.storefrontImageUrl,
    required this.businessRegistrationNumber,
    required this.taxId,
    required this.leadSource,
    required this.createdDate,
    required this.expectedRevenue,
    required this.currentRevenue,
    required this.assignedRepName,
    required this.creditLimit,
    required this.creditStatus,
    required this.stage,
    required this.priority,
    required this.industry,
    required this.territory,
    this.interestedProducts = const [],
    this.notes = const [],
    this.contacts = const [],
    this.documents = const [],
    this.opportunityInfo,
    this.wonInfo,
  });

  final String id;

  /// Latin trade name. Kept under its original name because the pipeline
  /// board, forms and activity log all read it; [displayName] is the
  /// localised accessor.
  final String companyName;

  /// Khmer trade name.
  ///
  /// Defaulted rather than required because a lead is *created by the rep in
  /// the field* — unlike a customer, there is no SAP record to read a Khmer
  /// name off. The capture form does not ask for one (a rep standing in a shop
  /// doorway should not be made to type the name twice), so most locally
  /// created leads carry only [companyName] and fall back to it in Khmer. Once
  /// the lead is approved and becomes a SAP customer, `name3` supplies the
  /// Khmer name properly.
  final String companyNameKh;

  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String province;
  final String district;
  final double latitude;
  final double longitude;
  final String storefrontImageUrl;
  final String businessRegistrationNumber;
  final String taxId;
  final LeadSource leadSource;
  final DateTime createdDate;
  final double expectedRevenue;
  final double currentRevenue;
  final String assignedRepName;
  final double creditLimit;
  final CreditStatus creditStatus;
  final PipelineStage stage;
  final Priority priority;
  final String industry;

  /// Sales territory (usually the province) — kept distinct from [province]
  /// so territory groupings can differ from strict admin geography later.
  final String territory;

  /// Product interest chips picked at creation time (Rebar/Mesh/Sheet/
  /// Sections/Mixed) — optional, non-blocking.
  final List<String> interestedProducts;

  final List<String> notes;
  final List<Contact> contacts;
  final List<LeadDocument> documents;
  final OpportunityInfo? opportunityInfo;
  final WonInfo? wonInfo;

  /// The company's name in both languages. Widgets render
  /// `context.localized(lead.displayName)`; Khmer falls back to the Latin name
  /// when [companyNameKh] is empty, which is the common case for leads a rep
  /// created in the field.
  LocalizedText get displayName =>
      LocalizedText(en: companyName, km: companyNameKh);

  /// Everything the pipeline search should match, in both languages at once.
  Iterable<String> get searchableValues sync* {
    yield* displayName.allValues;
    yield ownerName;
    yield phone;
  }

  Lead copyWith({
    PipelineStage? stage,
    Priority? priority,
    CreditStatus? creditStatus,
    double? currentRevenue,
    double? expectedRevenue,
    String? ownerName,
    List<String>? interestedProducts,
    List<String>? notes,
    List<Contact>? contacts,
    List<LeadDocument>? documents,
    OpportunityInfo? opportunityInfo,
    WonInfo? wonInfo,
  }) {
    return Lead(
      id: id,
      companyName: companyName,
      companyNameKh: companyNameKh,
      ownerName: ownerName ?? this.ownerName,
      phone: phone,
      email: email,
      address: address,
      province: province,
      district: district,
      latitude: latitude,
      longitude: longitude,
      storefrontImageUrl: storefrontImageUrl,
      businessRegistrationNumber: businessRegistrationNumber,
      taxId: taxId,
      leadSource: leadSource,
      createdDate: createdDate,
      expectedRevenue: expectedRevenue ?? this.expectedRevenue,
      currentRevenue: currentRevenue ?? this.currentRevenue,
      assignedRepName: assignedRepName,
      creditLimit: creditLimit,
      creditStatus: creditStatus ?? this.creditStatus,
      stage: stage ?? this.stage,
      priority: priority ?? this.priority,
      industry: industry,
      territory: territory,
      interestedProducts: interestedProducts ?? this.interestedProducts,
      notes: notes ?? this.notes,
      contacts: contacts ?? this.contacts,
      documents: documents ?? this.documents,
      opportunityInfo: opportunityInfo ?? this.opportunityInfo,
      wonInfo: wonInfo ?? this.wonInfo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyName,
        companyNameKh,
        ownerName,
        phone,
        email,
        address,
        province,
        district,
        latitude,
        longitude,
        storefrontImageUrl,
        businessRegistrationNumber,
        taxId,
        leadSource,
        createdDate,
        expectedRevenue,
        currentRevenue,
        assignedRepName,
        creditLimit,
        creditStatus,
        stage,
        priority,
        industry,
        territory,
        interestedProducts,
        notes,
        contacts,
        documents,
        opportunityInfo,
        wonInfo,
      ];
}
