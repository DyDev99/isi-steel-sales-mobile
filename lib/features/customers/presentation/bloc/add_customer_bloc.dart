// =============================================================================
// add_customer_bloc.dart
//
// Replaces the old bloc. The whole form is now ONE object (BpCustomerDraft)
// instead of three events with fixed parameter lists, so adding a SAP field
// never touches this file.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
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
    );
  }
}

// -----------------------------------------------------------------------------
// Bloc
// -----------------------------------------------------------------------------
class AddCustomerBloc extends Bloc<AddCustomerEvent, AddCustomerState> {
  final BusinessPartnerRepository _repository;
  final RepSalesContext _rep;

  AddCustomerBloc({
    required BusinessPartnerRepository repository,
    required RepSalesContext rep,
    BpCustomerDraft? initialDraft,
  })  : _repository = repository,
        _rep = rep,
        super(AddCustomerState(
          currentStep: BpFormStep.identity,
          draft: initialDraft ?? BpCustomerDraft(),
        )) {
    debugPrint('[CustomerRegistration] Form opened step=1 identity');
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
      debugPrint('[CustomerRegistration] Draft opened '
          'draftId=${serverDraft.draftId} status=${serverDraft.status} '
          'resumed=${opened.resumed}');
      // Every non-null field the server holds is written back onto the form,
      // so a resumed draft reopens with each step already filled in.
      final draft = state.draft..applyServerFields(serverDraft.fields);
      draft.applyDerivations();
      emit(state.copyWith(
        draft: draft,
        serverDraftId: serverDraft.draftId,
        serverFields: Map<String, dynamic>.from(serverDraft.fields),
        status: AddCustomerStatus.editing,
        resumedDraft: opened.resumed,
      ));
    } catch (e) {
      debugPrint(
          '[CustomerRegistration] Draft open failed errorType=${e.runtimeType}');
      emit(state.copyWith(
        status: AddCustomerStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onDraftChanged(DraftChanged event, Emitter<AddCustomerState> emit) {
    event.mutate(state.draft);
    state.draft.applyDerivations();

    // Clear only the errors the rep has now fixed — keep the rest visible.
    final remaining = Map<String, String>.from(state.errors)
      ..removeWhere((key, _) =>
          !state.draft.validateStep(state.currentStep).containsKey(key));

    emit(state.copyWith(errors: remaining));
    debugPrint('[CustomerRegistration] Step ${state.currentStep.number} '
        '${state.currentStep.name}: field change captured');
    _persistDraft();
  }

  Future<void> _onNextStep(
      NextStep event, Emitter<AddCustomerState> emit) async {
    debugPrint('[CustomerRegistration] Next pressed at step '
        '${state.currentStep.number} ${state.currentStep.name}');
    final errors = state.draft.validateStep(state.currentStep);
    if (errors.isNotEmpty) {
      debugPrint(
          '[CustomerRegistration] Step ${state.currentStep.number} blocked '
          'invalidFields=${errors.keys.join(',')}');
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
    debugPrint('[CustomerRegistration] Entered step '
        '${state.currentStep.number} ${state.currentStep.name}');
    _persistDraft();
  }

  void _onPreviousStep(PreviousStep event, Emitter<AddCustomerState> emit) {
    if (state.isFirstStep) return;
    emit(state.copyWith(
      currentStep: BpFormStep.values[state.currentStep.index - 1],
    ));
    debugPrint('[CustomerRegistration] Returned to step '
        '${state.currentStep.number} ${state.currentStep.name}');
  }

  /// Used by the review screen's edit pencils — jump back without re-walking.
  void _onGoToStep(GoToStep event, Emitter<AddCustomerState> emit) {
    emit(state.copyWith(currentStep: event.step));
    debugPrint('[CustomerRegistration] Jumped to step '
        '${event.step.number} ${event.step.name}');
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
    debugPrint('[CustomerRegistration] Submit requested');
    for (final step in BpFormStep.values) {
      final errors = state.draft.validateStep(step);
      if (errors.isNotEmpty) {
        debugPrint('[CustomerRegistration] Submit blocked at step '
            '${step.number} ${step.name} invalidFields=${errors.keys.join(',')}');
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

      debugPrint('[CustomerRegistration] Compatibility submit complete '
          'status=${result.queuedOffline ? 'queued' : 'accepted'}');

      emit(state.copyWith(
        status: AddCustomerStatus.success,
        queuedOffline: result.queuedOffline,
      ));
      await _repository.clearDraft();
    } catch (e) {
      debugPrint('[CustomerRegistration] Submit failed '
          'errorType=${e.runtimeType}');
      emit(state.copyWith(
        status: AddCustomerStatus.failure,
        errorMessage: e.toString(),
      ));
    }
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
    debugPrint('[CustomerRegistration] Local draft save requested '
        'step=${state.currentStep.number} ${state.currentStep.name}');
    _repository.saveDraft(state.draft);
  }
}
