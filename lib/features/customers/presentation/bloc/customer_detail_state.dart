import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_note.dart';

sealed class CustomerDetailState extends Equatable {
  const CustomerDetailState();
  @override
  List<Object?> get props => [];
}

final class CustomerDetailLoading extends CustomerDetailState {
  const CustomerDetailLoading();
}

final class CustomerDetailLoaded extends CustomerDetailState {
  const CustomerDetailLoaded({
    required this.customer,
    required this.notes,
    required this.activities,
    this.isAddingNote = false,
  });

  final Customer customer;
  final List<CustomerNote> notes;
  final List<CustomerActivity> activities;
  final bool isAddingNote;

  CustomerDetailLoaded copyWith({
    Customer? customer,
    List<CustomerNote>? notes,
    List<CustomerActivity>? activities,
    bool? isAddingNote,
  }) {
    return CustomerDetailLoaded(
      customer: customer ?? this.customer,
      notes: notes ?? this.notes,
      activities: activities ?? this.activities,
      isAddingNote: isAddingNote ?? this.isAddingNote,
    );
  }

  @override
  List<Object?> get props => [customer, notes, activities, isAddingNote];
}

final class CustomerDetailError extends CustomerDetailState {
  const CustomerDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
