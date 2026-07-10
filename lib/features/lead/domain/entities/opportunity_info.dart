import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/budget_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_sub_stage.dart';

/// Everything about an opportunity beyond the one number required to open
/// it ([estimatedValue]) is optional and filled in whenever the rep
/// actually learns it — never asked upfront as a blocking form.
class OpportunityInfo extends Equatable {
  const OpportunityInfo({
    required this.estimatedValue,
    this.subStage = OpportunitySubStage.qualifying,
    this.expectedClosingDate,
    this.tonnage,
    this.productGrade,
    this.budgetStatus,
    this.hasDecisionMakerAccess,
    this.productsInterested = const [],
    this.lastContact,
  });

  final double estimatedValue;
  final OpportunitySubStage subStage;
  final DateTime? expectedClosingDate;
  final double? tonnage;
  final String? productGrade;
  final BudgetStatus? budgetStatus;
  final bool? hasDecisionMakerAccess;
  final List<String> productsInterested;
  final DateTime? lastContact;

  OpportunityInfo copyWith({
    double? estimatedValue,
    OpportunitySubStage? subStage,
    DateTime? expectedClosingDate,
    double? tonnage,
    String? productGrade,
    BudgetStatus? budgetStatus,
    bool? hasDecisionMakerAccess,
    List<String>? productsInterested,
    DateTime? lastContact,
  }) {
    return OpportunityInfo(
      estimatedValue: estimatedValue ?? this.estimatedValue,
      subStage: subStage ?? this.subStage,
      expectedClosingDate: expectedClosingDate ?? this.expectedClosingDate,
      tonnage: tonnage ?? this.tonnage,
      productGrade: productGrade ?? this.productGrade,
      budgetStatus: budgetStatus ?? this.budgetStatus,
      hasDecisionMakerAccess:
          hasDecisionMakerAccess ?? this.hasDecisionMakerAccess,
      productsInterested: productsInterested ?? this.productsInterested,
      lastContact: lastContact ?? this.lastContact,
    );
  }

  @override
  List<Object?> get props => [
        estimatedValue,
        subStage,
        expectedClosingDate,
        tonnage,
        productGrade,
        budgetStatus,
        hasDecisionMakerAccess,
        productsInterested,
        lastContact,
      ];
}
