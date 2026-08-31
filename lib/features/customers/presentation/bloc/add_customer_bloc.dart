// =============================================================================
// add_customer_bloc.dart
//
// Replaces the old bloc. The whole form is now ONE object (BpCustomerDraft)
// instead of three events with fixed parameter lists, so adding a SAP field
// never touches this file.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/logging/debug_trace.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/sap_reference_options.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_document_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_document.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/business_partner_repository.dart';

// -----------------------------------------------------------------------------
// Events
// -----------------------------------------------------------------------------
abstract class AddCustomerEvent {
  const AddCustomerEvent();
}

/// The rep changed something. [mutate] writes straight onto the draft.
///
///   bloc.add(DraftChanged((d) => d.nameEn = value));
class DraftChanged extends AddCustomerEvent {
  final void Function(BpCustomerDraft draft) mutate;
  const DraftChanged(this.mutate);
}

/// Starts the server-owned draft as soon as the add-customer sheet opens.
class OpenServerDraft extends AddCustomerEvent {
  const OpenServerDraft();
}

class NextStep extends AddCustomerEvent {
  const NextStep();
}

class PreviousStep extends AddCustomerEvent {
  const PreviousStep();
}

class GoToStep extends AddCustomerEvent {
  final BpFormStep step;
  const GoToStep(this.step);
}

class AttachmentAdded extends AddCustomerEvent {
  final BpAttachment attachment;
  const AttachmentAdded(this.attachment);
}

class AttachmentRemoved extends AddCustomerEvent {
  final String kind;
  const AttachmentRemoved(this.kind);
}

class SubmitToHQ extends AddCustomerEvent {
  const SubmitToHQ();
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------
enum AddCustomerStatus { opening, editing, submitting, success, failure }

class AddCustomerState {
  final BpFormStep currentStep;
  final BpCustomerDraft draft;
  final String? serverDraftId;

  /// Last complete field map returned by the API. It lets each update send a
  /// true patch instead of re-posting the whole form.
  final Map<String, dynamic> serverFields;
  final AddCustomerStatus status;

  /// field key -> i18n error key. Populated only after a failed Next/Submit,
  /// so the rep is not shouted at while still typing.
  final Map<String, String> errors;
  final String? errorMessage;

  /// True once the record is queued locally but not yet confirmed by SAP.
  final bool queuedOffline;

  /// True when the form was restored from a draft the rep had already started,
  /// rather than opened blank. The UI says so — a pre-filled form with no
  /// explanation reads as a bug.
  final bool resumedDraft;

  /// Evidence slots that did not reach the server, if any.
  ///
  /// The registration still succeeded — a customer is never lost to a
  /// photograph — so this is reported alongside success rather than as a
  /// failure the rep has to clear before continuing.
  final List<CustomerDocumentType> unsentDocuments;

  /// ERP catalogues backing the SAP-code dropdowns.
  ///
  /// Defaults to [SapReferenceOptions.empty], which resolves every dropdown to
  /// the built-in list — so the form is usable before (and without) a
  /// successful reference load.
  final SapReferenceOptions references;

  const AddCustomerState({
    required this.currentStep,
    required this.draft,
    this.serverDraftId,
    this.serverFields = const {},
    this.status = AddCustomerStatus.editing,
    this.errors = const {},
    this.errorMessage,
    this.queuedOffline = false,
    this.resumedDraft = false,
    this.references = SapReferenceOptions.empty,
    this.unsentDocuments = const [],
  });

  bool get isFirstStep => currentStep.index == 0;
  bool get isLastStep => currentStep.index == BpFormStep.values.length - 1;

  /// NOTE: deliberately NOT Equatable. The draft is mutable, so value equality
  /// would swallow edits. Every emit creates a new instance, and identity
  /// comparison makes bloc rebuild every time.
  AddCustomerState copyWith({
    BpFormStep? currentStep,
    BpCustomerDraft? draft,
    String? serverDraftId,
    Map<String, dynamic>? serverFields,
    AddCustomerStatus? status,
    Map<String, String>? errors,
    String? errorMessage,
    bool? queuedOffline,
    bool? resumedDraft,
    SapReferenceOptions? references,
    List<CustomerDocumentType>? unsentDocuments,
  }) {
    return AddCustomerState(
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
      serverDraftId: serverDraftId ?? this.serverDraftId,
      serverFields: serverFields ?? this.serverFields,
      status: status ?? this.status,
      errors: errors ?? const {},
      errorMessage: errorMessage,
      queuedOffline: queuedOffline ?? this.queuedOffline,
      resumedDraft: resumedDraft ?? this.resumedDraft,
      references: references ?? this.references,
      unsentDocuments: unsentDocuments ?? this.unsentDocuments,
    );
  }
}

// -----------------------------------------------------------------------------
// Bloc
// -----------------------------------------------------------------------------
/// Console tracer for the registration flow. Debug builds only; see
/// [DebugTrace] for what may and may not be traced.
const _trace = DebugTrace('registration');

class AddCustomerBloc extends Bloc<AddCustomerEvent, AddCustomerState> {
  final BusinessPartnerRepository _repository;
  final CustomerDocumentRepository _documents;
  final RepSalesContext _rep;

  AddCustomerBloc({
    required BusinessPartnerRepository repository,
    required CustomerDocumentRepository documents,
    required RepSalesContext rep,
    BpCustomerDraft? initialDraft,
  })  : _repository = repository,
        _documents = documents,
        _rep = rep,
        super(AddCustomerState(
          currentStep: BpFormStep.identity,
          draft: initialDraft ?? BpCustomerDraft(),
        )) {
    _trace.begin('customer registration');
    _trace.step('form', 'opened', {'step': '1/5 identity'});
    on<OpenServerDraft>(_onOpenServerDraft);
    on<DraftChanged>(_onDraftChanged);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<AttachmentAdded>(_onAttachmentAdded);
    on<AttachmentRemoved>(_onAttachmentRemoved);
    on<SubmitToHQ>(_onSubmit);
  }

  Future<void> _onOpenServerDraft(
      OpenServerDraft event, Emitter<AddCustomerState> emit) async {
    emit(state.copyWith(status: AddCustomerStatus.opening));
    try {
      // Resumes the rep's open form when there is one, and only creates a new
      // draft otherwise — see BusinessPartnerRepository.openDraft.
      final opened = await _repository.openDraft();
      final serverDraft = opened.draft;
      if (serverDraft.draftId.isEmpty) {
        throw StateError('The server did not return a draft ID.');
      }
      _trace.ok('draft', opened.resumed ? 'resumed' : 'created', {
        'id': DebugTrace.id(serverDraft.draftId),
        'status': serverDraft.status,
        'fields': serverDraft.fields.length,
      });
      // Every non-null field the server holds is written back onto the form,
      // so a resumed draft reopens with each step already filled in.
      final draft = state.draft..applyServerFields(serverDraft.fields);
      // Loaded after the draft, not before: the form must open even when the
      // reference endpoint is unreachable, and `loadReferenceOptions` already
      // degrades to a cached or built-in list rather than throwing.
      final references = await _repository.loadReferenceOptions();
      // Derived only once the catalogues are in hand, so the price group is
      // matched against the ERP's own pairing rather than the built-in map.
      draft.applyDerivations(priceGroupResolver: references.priceGroupFor);
      _trace.step('refs', references.isFromErp ? 'from ERP' : 'built-in', {
        'synced': references.synchronisedAt?.toIso8601String(),
      });

      emit(state.copyWith(
        draft: draft,
        serverDraftId: serverDraft.draftId,
        serverFields: Map<String, dynamic>.from(serverDraft.fields),
        status: AddCustomerStatus.editing,
        resumedDraft: opened.resumed,
        references: references,
      ));
    } catch (e) {
      _trace.fail('draft', 'open failed', {'error': e.runtimeType});
      emit(state.copyWith(
        status: AddCustomerStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onDraftChanged(DraftChanged event, Emitter<AddCustomerState> emit) {
    event.mutate(state.draft);
    state.draft
        .applyDerivations(priceGroupResolver: state.references.priceGroupFor);

    // Clear only the errors the rep has now fixed — keep the rest visible.
    final remaining = Map<String, String>.from(state.errors)
      ..removeWhere((key, _) =>
          !state.draft.validateStep(state.currentStep).containsKey(key));

    emit(state.copyWith(errors: remaining));
    _trace.step('edit',
        '${state.currentStep.number}/5 ${state.currentStep.name}', const {});
    _persistDraft();
  }

  Future<void> _onNextStep(
      NextStep event, Emitter<AddCustomerState> emit) async {
    _trace.step('next',
        '${state.currentStep.number}/5 ${state.currentStep.name}', const {});
    final errors = state.draft.validateStep(state.currentStep);
    if (errors.isNotEmpty) {
      _trace.fail(
        'step',
        '${state.currentStep.number}/5 ${state.currentStep.name}',
        {'missing': DebugTrace.names(errors.keys)},
      );
      emit(state.copyWith(errors: errors));
      return;
    }
    if (state.isLastStep) return;

    try {
      await _flushServerChanges(emit);
      emit(state.copyWith(
        currentStep: BpFormStep.values[state.currentStep.index + 1],
        status: AddCustomerStatus.editing,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: AddCustomerStatus.failure, errorMessage: e.toString()));
      return;
    }
    _trace.ok('step', '${state.currentStep.number}/5 ${state.currentStep.name}',
        const {});
    _persistDraft();
  }

  void _onPreviousStep(PreviousStep event, Emitter<AddCustomerState> emit) {
    if (state.isFirstStep) return;
    emit(state.copyWith(
      currentStep: BpFormStep.values[state.currentStep.index - 1],
    ));
    _trace.step('back',
        '${state.currentStep.number}/5 ${state.currentStep.name}', const {});
  }

  /// Used by the review screen's edit pencils — jump back without re-walking.
  void _onGoToStep(GoToStep event, Emitter<AddCustomerState> emit) {
    emit(state.copyWith(currentStep: event.step));
    _trace.step('jump', '${event.step.number}/5 ${event.step.name}', const {});
  }

  void _onAttachmentAdded(
      AttachmentAdded event, Emitter<AddCustomerState> emit) {
    state.draft.attachments
      ..removeWhere((a) => a.kind == event.attachment.kind)
      ..add(event.attachment);
    emit(state.copyWith());
    _persistDraft();
  }

  void _onAttachmentRemoved(
      AttachmentRemoved event, Emitter<AddCustomerState> emit) {
    state.draft.attachments.removeWhere((a) => a.kind == event.kind);
    emit(state.copyWith());
    _persistDraft();
  }

  Future<void> _onSubmit(
      SubmitToHQ event, Emitter<AddCustomerState> emit) async {
    // Validate EVERY step, not just the visible one. On tablet all steps show
    // at once, and on phone the rep can jump back via GoToStep and break an
    // earlier step after it was already passed.
    _trace.send('submit', 'requested');
    for (final step in BpFormStep.values) {
      final errors = state.draft.validateStep(step);
      if (errors.isNotEmpty) {
        _trace.fail('submit', 'blocked at ${step.number}/5 ${step.name}',
            {'missing': DebugTrace.names(errors.keys)});
        emit(state.copyWith(currentStep: step, errors: errors));
        return;
      }
    }

    emit(state.copyWith(status: AddCustomerStatus.submitting));

    try {
      await _flushServerChanges(emit);
      final draftId = state.serverDraftId;
      if (draftId == null) {
        throw StateError('Customer draft has not been created.');
      }
      final result = await _repository.submitServerDraft(draftId);

      _trace.ok('submit', result.queuedOffline ? 'queued' : 'accepted', {
        'customer': DebugTrace.id(result.localId),
        'code': result.customerCode,
      });

      // Evidence goes up only now: the documents endpoint is addressed by
      // customer id, which did not exist until this moment.
      final unsent =
          await _uploadEvidence(result.localId, result.queuedOffline);

      emit(state.copyWith(
        status: AddCustomerStatus.success,
        queuedOffline: result.queuedOffline,
        unsentDocuments: unsent,
      ));
      await _repository.clearDraft();
    } catch (e) {
      _trace.fail('submit', 'failed', {'error': e.runtimeType});
      emit(state.copyWith(
        status: AddCustomerStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Uploads the captured photographs against the newly created customer.
  ///
  /// Returns the slots that did not make it. **Never throws**: the customer has
  /// already been created, and letting a photograph fail the registration would
  /// lose a shop the rep is standing in for a reason unrelated to it. The
  /// server blocks HQ approval on its own `isComplete` instead
  /// (`docs/feature/customer/mobile/customer-documents.md` §The checklist).
  Future<List<CustomerDocumentType>> _uploadEvidence(
    String customerId,
    bool queuedOffline,
  ) async {
    final attachments = state.draft.attachments;
    if (attachments.isEmpty) return const [];

    // A queued registration has no server-side customer to attach to yet, and
    // no id worth uploading against. The photographs stay on the device.
    if (queuedOffline || customerId.isEmpty) {
      _trace.warn('photos', 'deferred — no server customer id yet',
          {'held': attachments.length});
      return attachments
          .map((a) => a.documentType)
          .whereType<CustomerDocumentType>()
          .toList();
    }

    final pending = <PendingCustomerDocument>[];
    for (final attachment in attachments) {
      final type = attachment.documentType;
      // A kind with no matching slot cannot be uploaded. Skipped rather than
      // guessed — sending it to the wrong slot would be worse than not sending
      // it, because the rep would see it as filed.
      if (type == null) {
        _trace.warn('photos', 'unknown slot', {'kind': attachment.kind});
        continue;
      }
      pending.add(PendingCustomerDocument(
        type: type,
        filePath: attachment.localPath,
        capturedAt: attachment.capturedAt,
      ));
    }
    if (pending.isEmpty) return const [];

    final result = await _documents.uploadAll(
      customerId: customerId,
      documents: pending,
    );

    return result.when(
      success: (outcome) {
        final clean = outcome.isCompleteSuccess;
        (clean ? _trace.ok : _trace.warn)(
            'photos', clean ? 'all sent' : 'partial', {
          'sent': outcome.uploaded.length,
          'retry': outcome.failed.length,
          'rejected': outcome.rejected.length,
        });
        return outcome.outstanding;
      },
      // uploadAll is contracted never to report overall failure; this branch
      // exists so a future change to that contract cannot silently drop the
      // slots on the floor.
      failure: (_) => pending.map((p) => p.type).toList(),
    );
  }

  /// Sends only fields whose current values differ from the last server draft.
  /// The update response is authoritative and is rebound before moving on.
  Future<void> _flushServerChanges(Emitter<AddCustomerState> emit) async {
    final draftId = state.serverDraftId;
    if (draftId == null) {
      throw StateError('Customer draft has not been created.');
    }
    final current = state.draft.toSapPayload(_rep)
      ..remove('attachments')
      ..remove('submitToSap');
    final changed = <String, dynamic>{
      for (final entry in current.entries)
        if (state.serverFields.containsKey(entry.key) &&
            state.serverFields[entry.key] != entry.value)
          entry.key: entry.value,
    };
    if (changed.isEmpty) return;

    final serverDraft = await _repository.updateServerDraft(
      draftId: draftId,
      changedFields: changed,
    );
    final rebound = state.draft..applyServerFields(serverDraft.fields);
    emit(state.copyWith(
      draft: rebound,
      serverDraftId:
          serverDraft.draftId.isEmpty ? draftId : serverDraft.draftId,
      serverFields: Map<String, dynamic>.from(serverDraft.fields),
    ));
  }

  /// Fire-and-forget local persistence so a killed app does not lose the form.
  void _persistDraft() {
    _trace.step('cache', 'local draft saved',
        {'step': '${state.currentStep.number}/5'});
    _repository.saveDraft(state.draft);
  }
}
