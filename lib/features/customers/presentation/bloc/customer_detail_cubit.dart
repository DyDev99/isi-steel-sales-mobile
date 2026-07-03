import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/add_customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/add_customer_note.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_customer_activities.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_customer_notes.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_by_id.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/record_customer_viewed.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_state.dart';

class CustomerDetailCubit extends Cubit<CustomerDetailState> {
  CustomerDetailCubit({
    required GetCustomerById getCustomerById,
    required FetchCustomerNotes fetchCustomerNotes,
    required AddCustomerNote addCustomerNote,
    required FetchCustomerActivities fetchCustomerActivities,
    required AddCustomerActivity addCustomerActivity,
    required RecordCustomerViewed recordCustomerViewed,
  })  : _getCustomerById = getCustomerById,
        _fetchCustomerNotes = fetchCustomerNotes,
        _addCustomerNote = addCustomerNote,
        _fetchCustomerActivities = fetchCustomerActivities,
        _addCustomerActivity = addCustomerActivity,
        _recordCustomerViewed = recordCustomerViewed,
        super(const CustomerDetailLoading());

  final GetCustomerById _getCustomerById;
  final FetchCustomerNotes _fetchCustomerNotes;
  final AddCustomerNote _addCustomerNote;
  final FetchCustomerActivities _fetchCustomerActivities;
  final AddCustomerActivity _addCustomerActivity;
  final RecordCustomerViewed _recordCustomerViewed;

  Future<void> load(String customerId) async {
    emit(const CustomerDetailLoading());
    unawaited(_recordCustomerViewed(CustomerIdParams(customerId)));

    final customerResult = await _getCustomerById(CustomerIdParams(customerId));
    await customerResult.when(
      success: (customer) async {
        final notesResult = await _fetchCustomerNotes(CustomerIdParams(customerId));
        final activitiesResult = await _fetchCustomerActivities(CustomerIdParams(customerId));
        emit(CustomerDetailLoaded(
          customer: customer,
          notes: notesResult.when(success: (n) => n, failure: (_) => const []),
          activities: activitiesResult.when(success: (a) => a, failure: (_) => const []),
        ));
      },
      failure: (f) async => emit(CustomerDetailError(f.message)),
    );
  }

  Future<void> addNote(String body) async {
    final current = state;
    if (current is! CustomerDetailLoaded || body.trim().isEmpty) return;

    emit(current.copyWith(isAddingNote: true));
    final result = await _addCustomerNote(
      AddCustomerNoteParams(customerId: current.customer.id, body: body.trim()),
    );
    await result.when(
      success: (_) async {
        await _addCustomerActivity(AddCustomerActivityParams(CustomerActivity(
          id: '${current.customer.id}-ACT-${DateTime.now().microsecondsSinceEpoch}',
          customerId: current.customer.id,
          type: CustomerActivityType.note,
          summary: body.trim(),
          createdAt: DateTime.now(),
        )));
        final notesResult = await _fetchCustomerNotes(CustomerIdParams(current.customer.id));
        final activitiesResult = await _fetchCustomerActivities(CustomerIdParams(current.customer.id));
        emit(current.copyWith(
          notes: notesResult.when(success: (n) => n, failure: (_) => current.notes),
          activities: activitiesResult.when(success: (a) => a, failure: (_) => current.activities),
          isAddingNote: false,
        ));
      },
      failure: (_) async => emit(current.copyWith(isAddingNote: false)),
    );
  }

  Future<void> logActivity(CustomerActivityType type, String summary) async {
    final current = state;
    if (current is! CustomerDetailLoaded) return;

    await _addCustomerActivity(AddCustomerActivityParams(CustomerActivity(
      id: '${current.customer.id}-ACT-${DateTime.now().microsecondsSinceEpoch}',
      customerId: current.customer.id,
      type: type,
      summary: summary,
      createdAt: DateTime.now(),
    )));
    final activitiesResult = await _fetchCustomerActivities(CustomerIdParams(current.customer.id));
    emit(current.copyWith(activities: activitiesResult.when(success: (a) => a, failure: (_) => current.activities)));
  }
}
