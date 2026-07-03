import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/activity_log_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/add_lead_activity.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/add_lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/add_lead_note.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/fetch_lead_activity.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/get_lead_by_id.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_id_params.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/lead_detail_state.dart';

/// Read/write for a single lead's detail screen (general info, activity,
/// notes, documents). Stage moves are dispatched through the shared
/// [PipelineBloc] instead (see LeadDetailScreen), so the board stays in
/// sync; this cubit just reloads afterwards to reflect the new stage.
class LeadDetailCubit extends Cubit<LeadDetailState> {
  LeadDetailCubit({
    required GetLeadById getLeadById,
    required FetchLeadActivity fetchLeadActivity,
    required AddLeadNote addLeadNote,
    required AddLeadDocument addLeadDocument,
    required AddLeadActivity addLeadActivity,
  })  : _getLeadById = getLeadById,
        _fetchLeadActivity = fetchLeadActivity,
        _addLeadNote = addLeadNote,
        _addLeadDocument = addLeadDocument,
        _addLeadActivity = addLeadActivity,
        super(const LeadDetailInitial());

  final GetLeadById _getLeadById;
  final FetchLeadActivity _fetchLeadActivity;
  final AddLeadNote _addLeadNote;
  final AddLeadDocument _addLeadDocument;
  final AddLeadActivity _addLeadActivity;
  String? _leadId;

  Future<void> load(String leadId) async {
    _leadId = leadId;
    emit(const LeadDetailLoading());
    try {
      final lead = await _getLeadById(LeadIdParams(leadId));
      final activity = await _fetchLeadActivity(LeadIdParams(leadId));
      emit(LeadDetailLoaded(lead: lead, activity: activity));
    } catch (_) {
      emit(const LeadDetailError("Couldn't load this customer"));
    }
  }

  Future<void> reload() {
    final id = _leadId;
    if (id == null) return Future.value();
    return load(id);
  }

  Future<void> addNote(String note) async {
    final id = _leadId;
    if (id == null || note.trim().isEmpty) return;
    await _addLeadNote(AddLeadNoteParams(leadId: id, note: note.trim()));
    await _addLeadActivity(AddLeadActivityParams(
      leadId: id,
      item: ActivityLogItem(
        id: '$id-NOTE-${DateTime.now().microsecondsSinceEpoch}',
        kind: ActivityLogKind.note,
        title: 'Note added',
        description: note.trim(),
        timestamp: DateTime.now(),
        actor: 'You',
      ),
    ));
    await reload();
  }

  Future<void> addMockDocument(DocumentType type, String name) async {
    final id = _leadId;
    if (id == null) return;
    await _addLeadDocument(AddLeadDocumentParams(
      leadId: id,
      document: LeadDocument(
        id: '$id-DOC-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        type: type,
        url: 'mock://documents/${name.toLowerCase().replaceAll(' ', '_')}',
        uploadedDate: DateTime.now(),
      ),
    ));
    await _addLeadActivity(AddLeadActivityParams(
      leadId: id,
      item: ActivityLogItem(
        id: '$id-ACT-${DateTime.now().microsecondsSinceEpoch}',
        kind: ActivityLogKind.documentCollected,
        title: 'Document uploaded',
        description: name,
        timestamp: DateTime.now(),
        actor: 'You',
      ),
    ));
    await reload();
  }
}
