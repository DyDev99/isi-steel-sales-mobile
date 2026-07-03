import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/activity_log_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';

sealed class LeadDetailState extends Equatable {
  const LeadDetailState();
  @override
  List<Object?> get props => const [];
}

final class LeadDetailInitial extends LeadDetailState {
  const LeadDetailInitial();
}

final class LeadDetailLoading extends LeadDetailState {
  const LeadDetailLoading();
}

final class LeadDetailError extends LeadDetailState {
  const LeadDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

final class LeadDetailLoaded extends LeadDetailState {
  const LeadDetailLoaded({required this.lead, required this.activity});
  final Lead lead;
  final List<ActivityLogItem> activity;
  @override
  List<Object?> get props => [lead, activity];
}
