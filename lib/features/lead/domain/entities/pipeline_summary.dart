import 'package:equatable/equatable.dart';

class PipelineSummary extends Equatable {
  const PipelineSummary({
    required this.totalLeads,
    required this.totalOpportunities,
    required this.wonCustomers,
    required this.potentialRevenue,
    required this.wonRevenue,
    required this.conversionRate,
  });

  final int totalLeads;
  final int totalOpportunities;
  final int wonCustomers;
  final double potentialRevenue;
  final double wonRevenue;
  final double conversionRate; // 0..1, wonCustomers / totalCompanies

  @override
  List<Object?> get props => [
        totalLeads,
        totalOpportunities,
        wonCustomers,
        potentialRevenue,
        wonRevenue,
        conversionRate,
      ];
}
