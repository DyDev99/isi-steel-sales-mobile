// =============================================================================
// add_depot_bloc.dart
//
// The whole form is ONE object (BpDepotDraft) instead of an event per
// field, so adding a SAP field never touches this file.
//
// Rewritten for the single-write endpoint. The three-call server-draft
// protocol is gone: there is no `serverDraftId`, no per-step PATCH, and no
// network call before submit. The consequences are worth stating because they
// are the point of the change:
//
//   * The form opens offline. It used to need `POST /draft` to return an id
//     before the rep could type, which failed exactly where reps work.
//   * `Next` is instant. It used to flush a patch and await the response.
//   * A resumed form comes from the device, not the server — see
//     BusinessPartnerRepository.loadDraft.
// =============================================================================

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/logging/debug_trace.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/models/bp_depot_form_data.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/models/sap_reference_options.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/business_partner_request.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_document.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_submit_progress.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/business_partner_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_document_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/business_partner_submission.dart';

// -----------------------------------------------------------------------------
// Events
// -----------------------------------------------------------------------------
abstract class AddDepotEvent {
  const AddDepotEvent();
}

/// The rep changed something. [mutate] writes straight onto the draft.
///
///   bloc.add(DraftChanged((d) => d.nameEn = value));
class DraftChanged extends AddDepotEvent {
  final void Function(BpDepotDraft draft) mutate;
  const DraftChanged(this.mutate);
}

/// Loads the reference catalogues and any saved form.
///
/// Named `OpenForm` rather than the old `OpenServerDraft` because nothing
/// server-side is opened any more. Both steps degrade rather than fail, so
/// unlike its predecessor this event cannot leave the form unusable.
class OpenForm extends AddDepotEvent {
  const OpenForm();
}

class NextStep extends AddDepotEvent {
  const NextStep();
}

class PreviousStep extends AddDepotEvent {
  const PreviousStep();
}

class GoToStep extends AddDepotEvent {
  final BpFormStep step;
  const GoToStep(this.step);
}

class AttachmentAdded extends AddDepotEvent {
  final BpAttachment attachment;
  const AttachmentAdded(this.attachment);
}

class RetryUploadAttachment extends AddDepotEvent {
  final String kind;
  const RetryUploadAttachment(this.kind);
}

class AttachmentRemoved extends AddDepotEvent {
  final String kind;
  const AttachmentRemoved(this.kind);
}

/// Asks SAP whether the form would be accepted, without creating anything.
///
/// Optional and rep-triggered. It costs a round trip, and the rep is the only
/// one who knows whether the connection in this shop can afford one.
class ValidateWithSap extends AddDepotEvent {
  const ValidateWithSap();
}

class SubmitToHQ extends AddDepotEvent {
  const SubmitToHQ();
}

/// Throws away the saved form and starts blank. Reachable from the resume
/// banner — a rep who is registering a different shop must be able to say so.
class DiscardDraft extends AddDepotEvent {
  const DiscardDraft();
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------
enum AddDepotStatus {
  opening,
  editing,
  validating,
  submitting,
  success,
  failure,
}

class AddDepotState {
  final BpFormStep currentStep;
  final BpDepotDraft draft;
  final AddDepotStatus status;

  /// field key -> i18n error key. Populated only after a failed Next/Submit,
  /// so the rep is not shouted at while still typing.
  final Map<String, String> errors;
  final String? errorMessage;

  /// True once the record is held on the device but not yet confirmed by SAP.
  final bool queuedOffline;

  /// True when the form was restored from a draft the rep had already started,
  /// rather than opened blank. The UI says so — a pre-filled form with no
  /// explanation reads as a bug.
  final bool resumedDraft;

  /// Set once SAP has assigned a number. Empty while HQ approval is pending,
  /// so the success screen must not treat its absence as an error.
  final String? depotNumber;

  /// True when the registration was stored and is waiting on HQ approval
  /// rather than already numbered in SAP.
  ///
  /// The rep needs to be told which of the two happened: "sent for approval"
  /// and "depot 0000123456 created" are different promises, and showing the
  /// second when the first is true is how a rep comes to expect they can order
  /// against the shop today.
  final bool awaitingApproval;

  /// True when a `Commit: false` dry run last came back clean. Reset by any
  /// subsequent edit, because a form that has changed since the dry run has
  /// not been validated.
  final bool sapPreCheckPassed;

  /// Evidence slots that did not reach the server, if any.
  ///
  /// The registration still succeeded — a depot is never lost to a
  /// photograph — so this is reported alongside success rather than as a
  /// failure the rep has to clear before continuing.
  final List<DepotDocumentType> unsentDocuments;

  /// How far a submit has got. Drives the progress dialog; meaningless unless
  /// [status] is [AddDepotStatus.submitting].
  final DepotSubmitProgress progress;

  /// ERP catalogues backing the SAP-code dropdowns.
  ///
  /// Defaults to [SapReferenceOptions.empty], which resolves every dropdown to
  /// the built-in list — so the form is usable before (and without) a
  /// successful reference load.
  final SapReferenceOptions references;

  const AddDepotState({
    required this.currentStep,
    required this.draft,
    this.status = AddDepotStatus.editing,
    this.errors = const {},
    this.errorMessage,
    this.queuedOffline = false,
    this.resumedDraft = false,
    this.depotNumber,
    this.awaitingApproval = false,
    this.sapPreCheckPassed = false,
    this.references = SapReferenceOptions.empty,
    this.progress = const DepotSubmitProgress(),
    this.unsentDocuments = const [],
  });

  bool get isFirstStep => currentStep.index == 0;
  bool get isLastStep => currentStep.index == BpFormStep.values.length - 1;

  /// True while a network call owns the form and input must be inert.
  bool get isBusy =>
      status == AddDepotStatus.opening ||
      status == AddDepotStatus.validating ||
      status == AddDepotStatus.submitting;

  /// NOTE: deliberately NOT Equatable. The draft is mutable, so value equality
  /// would swallow edits. Every emit creates a new instance, and identity
  /// comparison makes bloc rebuild every time.
  AddDepotState copyWith({
    BpFormStep? currentStep,
    BpDepotDraft? draft,
    AddDepotStatus? status,
    Map<String, String>? errors,
    String? errorMessage,
    bool? queuedOffline,
    bool? resumedDraft,
    String? depotNumber,
    bool? awaitingApproval,
    bool? sapPreCheckPassed,
    SapReferenceOptions? references,
    DepotSubmitProgress? progress,
    List<DepotDocumentType>? unsentDocuments,
  }) {
    return AddDepotState(
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
      status: status ?? this.status,
      errors: errors ?? const {},
      errorMessage: errorMessage,
      queuedOffline: queuedOffline ?? this.queuedOffline,
      resumedDraft: resumedDraft ?? this.resumedDraft,
      depotNumber: depotNumber ?? this.depotNumber,
      awaitingApproval: awaitingApproval ?? this.awaitingApproval,
      sapPreCheckPassed: sapPreCheckPassed ?? this.sapPreCheckPassed,
      references: references ?? this.references,
      progress: progress ?? this.progress,
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

class AddDepotBloc extends Bloc<AddDepotEvent, AddDepotState> {
  final BusinessPartnerRepository _repository;
  final DepotDocumentRepository _documents;
  final BusinessPartnerSubmission _submission;
  final RepSalesContext _rep;
  Future<String?>? _depotCreationFuture;

  AddDepotBloc({
    required BusinessPartnerRepository repository,
    required DepotDocumentRepository documents,
    required BusinessPartnerSubmission submission,
    required RepSalesContext rep,
    BpDepotDraft? initialDraft,
  })  : _repository = repository,
        _documents = documents,
        _submission = submission,
        _rep = rep,
        super(AddDepotState(
          currentStep: BpFormStep.identity,
          draft: (initialDraft ?? BpDepotDraft())..applyRepDefaults(rep),
        )) {
    _trace.begin('depot registration');
    _trace.step('form', 'opened', {'step': '1/5 identity'});
    on<OpenForm>(_onOpenForm);
    on<DraftChanged>(_onDraftChanged);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<AttachmentAdded>(_onAttachmentAdded);
    on<RetryUploadAttachment>(_onRetryUploadAttachment);
    on<AttachmentRemoved>(_onAttachmentRemoved);
    on<ValidateWithSap>(_onValidateWithSap);
    on<SubmitToHQ>(_onSubmit);
    on<DiscardDraft>(_onDiscardDraft);
  }

  /// The rep's own sales area, exposed so the review screen can show what will
  /// be sent when they have not overridden it.
  RepSalesContext get rep => _rep;

  /// Builds the exact payload for the current form. Used by the review step.
  BusinessPartnerRequest previewRequest() => _submission.buildRequest(
        state.draft,
        rep: _rep,
        priceGroupResolver: state.references.priceGroupFor,
      );

  // ---------------------------------------------------------------------
  // Open
  // ---------------------------------------------------------------------

  Future<void> _onOpenForm(OpenForm event, Emitter<AddDepotState> emit) async {
    emit(state.copyWith(status: AddDepotStatus.opening));

    // Neither call throws by contract, so there is no try/catch and no path
    // where the form fails to open. That is the behavioural difference from
    // the old `OpenServerDraft`, which could and did leave the rep on an
    // error screen with no way forward.
    final saved = await _repository.loadDraft();
    final references = await _repository.loadReferenceOptions();

    final draft = saved ?? state.draft;
    draft.applyRepDefaults(_rep);
    // Derived only once the catalogues are in hand, so the price group is
    // matched against the ERP's own pairing rather than the built-in map.
    draft.applyDerivations(priceGroupResolver: references.priceGroupFor);

    _trace.step('refs', references.isFromErp ? 'from ERP' : 'built-in', {
      'synced': references.synchronisedAt?.toIso8601String(),
    });
    if (saved != null) {
      _trace.ok('draft', 'resumed from device', {
        'photos': saved.attachments.length,
      });
    }

    emit(state.copyWith(
      draft: draft,
      status: AddDepotStatus.editing,
      resumedDraft: saved != null,
      references: references,
    ));
  }

  Future<void> _onDiscardDraft(
      DiscardDraft event, Emitter<AddDepotState> emit) async {
    await _repository.clearDraft();
    _trace.step('draft', 'discarded by rep');
    emit(AddDepotState(
      currentStep: BpFormStep.identity,
      draft: BpDepotDraft()..applyRepDefaults(_rep),
      references: state.references,
    ));
  }

  // ---------------------------------------------------------------------
  // Editing
  // ---------------------------------------------------------------------

  void _onDraftChanged(DraftChanged event, Emitter<AddDepotState> emit) {
    event.mutate(state.draft);
    state.draft
        .applyDerivations(priceGroupResolver: state.references.priceGroupFor);

    // Clear only the errors the rep has now fixed — keep the rest visible.
    final remaining = Map<String, String>.from(state.errors)
      ..removeWhere((key, _) =>
          !state.draft.validateStep(state.currentStep).containsKey(key));

    emit(state.copyWith(
      errors: remaining,
      // Any edit invalidates a previous dry run. Keeping the pass would let a
      // rep change the payment term after SAP approved the old one and submit
      // on the strength of a check that no longer applies.
      sapPreCheckPassed: false,
    ));
    _trace.step('edit',
        '${state.currentStep.number}/5 ${state.currentStep.name}', const {});
    _persistDraft();
  }

  void _onNextStep(NextStep event, Emitter<AddDepotState> emit) {
    _trace.step('next',
        '${state.currentStep.number}/6 ${state.currentStep.name}', const {});

    final errors = state.draft.validateStep(state.currentStep);
    if (errors.isNotEmpty) {
      _trace.fail(
        'step',
        '${state.currentStep.number}/6 ${state.currentStep.name}',
        {'missing': DebugTrace.names(errors.keys)},
      );
      emit(state.copyWith(errors: errors));
      return;
    }

    if (state.currentStep == BpFormStep.documents) {
      if (!state.draft.allRequiredAttachmentsUploaded) {
        final anyUploading = state.draft.attachments.any((a) => a.isUploading);
        emit(state.copyWith(
          errorMessage: anyUploading
              ? 'add_depot.waiting_photo_upload'
              : 'add_depot.error.photo_not_uploaded',
        ));
        return;
      }
    }

    if (state.isLastStep) return;

    // No network call. `Next` used to flush a patch and await the response,
    // which made advancing a step fail in a dead spot.
    final nextStep = BpFormStep.values[state.currentStep.index + 1];
    emit(state.copyWith(
      currentStep: nextStep,
      status: AddDepotStatus.editing,
      errorMessage: null,
    ));
    _trace.ok('step', '${state.currentStep.number}/6 ${state.currentStep.name}',
        const {});
    _persistDraft();

    if (nextStep == BpFormStep.documents &&
        !state.draft.isDepotCreatedOnServer) {
      final idValid = state.draft.validateStep(BpFormStep.identity).isEmpty;
      final addrValid = state.draft.validateStep(BpFormStep.address).isEmpty;
      final contactValid = state.draft.validateStep(BpFormStep.contact).isEmpty;
      final salesValid =
          state.draft.validateStep(BpFormStep.salesTerms).isEmpty;
      if (idValid && addrValid && contactValid && salesValid) {
        unawaited(_ensureDepotCreatedOnServer());
      }
    }
  }

  void _onPreviousStep(PreviousStep event, Emitter<AddDepotState> emit) {
    if (state.isFirstStep) return;
    emit(state.copyWith(
      currentStep: BpFormStep.values[state.currentStep.index - 1],
    ));
    _trace.step('back',
        '${state.currentStep.number}/5 ${state.currentStep.name}', const {});
  }

  /// Used by the review screen's edit pencils — jump back without re-walking.
  void _onGoToStep(GoToStep event, Emitter<AddDepotState> emit) {
    emit(state.copyWith(currentStep: event.step));
    _trace.step('jump', '${event.step.number}/5 ${event.step.name}', const {});
    if (event.step == BpFormStep.documents &&
        !state.draft.isDepotCreatedOnServer) {
      final idValid = state.draft.validateStep(BpFormStep.identity).isEmpty;
      final addrValid = state.draft.validateStep(BpFormStep.address).isEmpty;
      final contactValid = state.draft.validateStep(BpFormStep.contact).isEmpty;
      final salesValid =
          state.draft.validateStep(BpFormStep.salesTerms).isEmpty;
      if (idValid && addrValid && contactValid && salesValid) {
        unawaited(_ensureDepotCreatedOnServer());
      }
    }
  }

  Future<void> _onAttachmentAdded(
      AttachmentAdded event, Emitter<AddDepotState> emit) async {
    final newAttachment = event.attachment.copyWith(
      isUploading: true,
      isUploaded: false,
      uploadError: null,
    );
    state.draft.attachments
      ..removeWhere((a) => a.kind == event.attachment.kind)
      ..add(newAttachment);
    emit(state.copyWith());
    _persistDraft();

    await _uploadSingleAttachment(newAttachment.kind, emit);
  }

  Future<void> _onRetryUploadAttachment(
      RetryUploadAttachment event, Emitter<AddDepotState> emit) async {
    final idx = state.draft.attachments.indexWhere((a) => a.kind == event.kind);
    if (idx != -1) {
      state.draft.attachments[idx] = state.draft.attachments[idx].copyWith(
        isUploading: true,
        isUploaded: false,
        uploadError: null,
      );
      emit(state.copyWith());
      await _uploadSingleAttachment(event.kind, emit);
    }
  }

  Future<String?> _ensureDepotCreatedOnServer() async {
    if (state.draft.isDepotCreatedOnServer) return null;
    if (_depotCreationFuture != null) return _depotCreationFuture!;

    _depotCreationFuture = _doCreateDepotDraft();
    try {
      final err = await _depotCreationFuture!;
      return err;
    } finally {
      _depotCreationFuture = null;
    }
  }

  Future<String?> _doCreateDepotDraft() async {
    if (state.draft.isDepotCreatedOnServer) return null;
    _trace.send('create-depot-draft', 'for attachment upload');
    final outcome = await _submission.submit(
      state.draft,
      rep: _rep,
      priceGroupResolver: state.references.priceGroupFor,
    );

    switch (outcome) {
      case BpSubmissionCreated(
          :final depotNumber,
          :final documentId,
          :final isPendingApproval,
        ):
        state.draft.serverDepotId =
            documentId.isNotEmpty ? documentId : depotNumber;
        state.draft.depotNumber = depotNumber;
        state.draft.isPendingHqApproval = isPendingApproval;
        _trace.ok('depot-draft', 'created for documents', {
          'depotId': state.draft.serverDepotId,
        });
        _persistDraft();
        return null;

      case BpSubmissionRejected(:final message):
        _trace.fail('depot-draft', 'creation rejected: $message');
        return message;

      case BpSubmissionUnreachable(:final message):
        _trace.warn('depot-draft', 'unreachable: $message');
        return message;
    }
  }

  Future<void> _uploadSingleAttachment(
      String kind, Emitter<AddDepotState> emit) async {
    final attachment = state.draft.getAttachment(kind);
    if (attachment == null) return;

    if (!state.draft.isDepotCreatedOnServer) {
      final err = await _ensureDepotCreatedOnServer();
      if (err != null || !state.draft.isDepotCreatedOnServer) {
        _markAttachmentFailed(
            kind, err ?? 'add_depot.photo_upload_failed', emit);
        return;
      }
    }

    final depotId = state.draft.serverDepotId!;
    final type = attachment.documentType;
    if (type == null) {
      _markAttachmentFailed(kind, 'Unknown document type', emit);
      return;
    }

    final outcomeResult = await _documents.uploadAll(
      depotId: depotId,
      documents: [
        PendingDepotDocument(
          type: type,
          filePath: attachment.localPath,
          capturedAt: attachment.capturedAt,
        ),
      ],
    );

    outcomeResult.when(
      success: (outcome) {
        if (outcome.uploaded.contains(type)) {
          _markAttachmentSuccess(kind, emit);
        } else {
          final err = outcome.rejected.contains(type)
              ? 'add_depot.error.photo_rejected'
              : 'add_depot.error.photo_failed';
          _markAttachmentFailed(kind, err, emit);
        }
      },
      failure: (failure) {
        _markAttachmentFailed(kind, failure.message, emit);
      },
    );
  }

  void _markAttachmentSuccess(String kind, Emitter<AddDepotState> emit) {
    final idx = state.draft.attachments.indexWhere((a) => a.kind == kind);
    if (idx != -1) {
      state.draft.attachments[idx] = state.draft.attachments[idx].copyWith(
        isUploading: false,
        isUploaded: true,
        uploadError: null,
      );
      emit(state.copyWith());
      _persistDraft();
    }
  }

  void _markAttachmentFailed(
      String kind, String? error, Emitter<AddDepotState> emit) {
    final idx = state.draft.attachments.indexWhere((a) => a.kind == kind);
    if (idx != -1) {
      state.draft.attachments[idx] = state.draft.attachments[idx].copyWith(
        isUploading: false,
        isUploaded: false,
        uploadError: error,
      );
      emit(state.copyWith());
      _persistDraft();
    }
  }

  void _onAttachmentRemoved(
      AttachmentRemoved event, Emitter<AddDepotState> emit) {
    state.draft.attachments.removeWhere((a) => a.kind == event.kind);
    emit(state.copyWith());
    _persistDraft();
  }

  // ---------------------------------------------------------------------
  // Validate
  // ---------------------------------------------------------------------

  Future<void> _onValidateWithSap(
      ValidateWithSap event, Emitter<AddDepotState> emit) async {
    final blocked = _firstIncompleteStep();
    if (blocked != null) {
      emit(state.copyWith(
        currentStep: blocked.step,
        errors: blocked.errors,
      ));
      return;
    }

    emit(state.copyWith(status: AddDepotStatus.validating));
    _trace.send('precheck', 'requested');

    final outcome = await _submission.validate(
      state.draft,
      rep: _rep,
      priceGroupResolver: state.references.priceGroupFor,
    );

    switch (outcome) {
      case BpSubmissionCreated():
        _trace.ok('precheck', 'SAP would accept');
        emit(state.copyWith(
          status: AddDepotStatus.editing,
          sapPreCheckPassed: true,
        ));
      case BpSubmissionRejected(:final message, :final step):
        _trace.fail('precheck', 'SAP would reject', const {});
        emit(state.copyWith(
          status: AddDepotStatus.editing,
          errorMessage: message,
          currentStep: step ?? state.currentStep,
        ));
      case BpSubmissionUnreachable(:final message):
        // Not a failure of the form. The rep can still submit, which will
        // queue if the connection is still down.
        _trace.warn('precheck', 'unreachable', const {});
        emit(state.copyWith(
          status: AddDepotStatus.editing,
          errorMessage: message,
        ));
    }
  }

  // ---------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------

  Future<void> _onSubmit(SubmitToHQ event, Emitter<AddDepotState> emit) async {
    _trace.send('submit', 'requested');

    // Validate EVERY step, not just the visible one. On tablet all steps show
    // at once, and on phone the rep can jump back via GoToStep and break an
    // earlier step after it was already passed.
    final blocked = _firstIncompleteStep();
    if (blocked != null) {
      _trace.fail(
          'submit',
          'blocked at ${blocked.step.number}/5 ${blocked.step.name}',
          {'missing': DebugTrace.names(blocked.errors.keys)});
      emit(state.copyWith(
        currentStep: blocked.step,
        errors: blocked.errors,
      ));
      return;
    }

    // If depot and photos already uploaded in Step 5:
    if (state.draft.isDepotCreatedOnServer) {
      _trace.ok('submit', 'already created on server, finalizing');
      emit(state.copyWith(
        status: AddDepotStatus.success,
        progress: const DepotSubmitProgress(stage: SubmitStage.finishing),
        depotNumber: state.draft.depotNumber.isNotEmpty
            ? state.draft.depotNumber
            : state.draft.serverDepotId,
        awaitingApproval: state.draft.isPendingHqApproval,
        queuedOffline: false,
        unsentDocuments: const [],
      ));
      await _repository.clearDraft();
      return;
    }

    emit(state.copyWith(
      status: AddDepotStatus.submitting,
      progress: const DepotSubmitProgress(stage: SubmitStage.registering),
    ));

    final outcome = await _submission.submit(
      state.draft,
      rep: _rep,
      priceGroupResolver: state.references.priceGroupFor,
    );

    switch (outcome) {
      case BpSubmissionCreated(
          :final depotNumber,
          :final documentId,
          :final isPendingApproval,
        ):
        _trace.ok('submit', isPendingApproval ? 'awaiting HQ' : 'accepted', {
          'depot': DebugTrace.id(depotNumber),
          'record': DebugTrace.id(documentId),
        });

        // Evidence goes up only now: the documents endpoint is addressed by
        // depot id, which did not exist until this moment.
        //
        // Addressed by `documentId`, not the SAP number. A record awaiting HQ
        // approval has no SAP number, and passing the empty string here made
        // `_uploadEvidence` treat every pending registration as having no
        // depot to attach to — so the photographs were held on the device
        // for a record that could perfectly well accept them.
        final photos = state.draft.attachments.length;
        if (photos > 0) {
          emit(state.copyWith(
            progress: DepotSubmitProgress(
              stage: SubmitStage.uploadingPhotos,
              photosTotal: photos,
            ),
          ));
        }

        final unsent = await _uploadEvidence(
          documentId,
          false,
          onPhotoProgress: (completed, total) {
            // `emit` after an await is safe while the handler is still running,
            // and this one only ever runs inside it.
            if (isClosed) return;
            emit(state.copyWith(
              progress: state.progress.copyWith(
                stage: SubmitStage.uploadingPhotos,
                photosSent: completed,
                photosTotal: total,
              ),
            ));
          },
        );

        emit(state.copyWith(
          status: AddDepotStatus.success,
          progress: state.progress.copyWith(stage: SubmitStage.finishing),
          depotNumber: depotNumber,
          awaitingApproval: isPendingApproval,
          queuedOffline: false,
          unsentDocuments: unsent,
        ));

        // Cleared last, and only on a confirmed create. Clearing before the
        // uploads would lose the local paths of any photograph that failed.
        await _repository.clearDraft();

      case BpSubmissionRejected(:final message, :final step):
        _trace.fail('submit', 'rejected', const {});
        emit(state.copyWith(
          status: AddDepotStatus.failure,
          errorMessage: message,
          currentStep: step ?? state.currentStep,
        ));

      case BpSubmissionUnreachable(:final message, :final mayHaveLanded):
        // The draft stays on the device on purpose. There is no offline
        // submission queue for this endpoint yet, so the rep's work is
        // preserved as a resumable form rather than silently dropped — see
        // the note in depots_injection.dart.
        await _repository.saveDraft(state.draft);
        _trace.warn('submit', mayHaveLanded ? 'unknown' : 'held', const {});
        emit(state.copyWith(
          status: AddDepotStatus.failure,
          queuedOffline: true,
          errorMessage: message,
        ));
    }
  }

  /// The first step that does not validate, or null when the form is complete.
  _BlockedStep? _firstIncompleteStep() {
    for (final step in BpFormStep.values) {
      final errors = state.draft.validateStep(step);
      if (errors.isNotEmpty) return _BlockedStep(step, errors);
    }
    return null;
  }

  /// Uploads the captured photographs against the newly created depot.
  ///
  /// Returns the slots that did not make it. **Never throws**: the depot has
  /// already been created, and letting a photograph fail the registration would
  /// lose a shop the rep is standing in for a reason unrelated to it. The
  /// server blocks HQ approval on its own `isComplete` instead
  /// (`docs/feature/depot/mobile/depot-documents.md` §The checklist).
  Future<List<DepotDocumentType>> _uploadEvidence(
    String depotId,
    bool queuedOffline, {
    void Function(int completed, int total)? onPhotoProgress,
  }) async {
    final attachments = state.draft.attachments;
    if (attachments.isEmpty) return const [];

    // A queued registration has no server-side depot to attach to yet, and
    // no id worth uploading against. The photographs stay on the device.
    if (queuedOffline || depotId.isEmpty) {
      _trace.warn('photos', 'deferred — no server depot id yet',
          {'held': attachments.length});
      return attachments
          .map((a) => a.documentType)
          .whereType<DepotDocumentType>()
          .toList();
    }

    final pending = <PendingDepotDocument>[];
    for (final attachment in attachments) {
      final type = attachment.documentType;
      // A kind with no matching slot cannot be uploaded. Skipped rather than
      // guessed — sending it to the wrong slot would be worse than not sending
      // it, because the rep would see it as filed.
      if (type == null) {
        _trace.warn('photos', 'unknown slot', {'kind': attachment.kind});
        continue;
      }
      pending.add(PendingDepotDocument(
        type: type,
        filePath: attachment.localPath,
        capturedAt: attachment.capturedAt,
      ));
    }
    if (pending.isEmpty) return const [];

    final result = await _documents.uploadAll(
      depotId: depotId,
      documents: pending,
      onProgress: onPhotoProgress,
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

  /// Fire-and-forget local persistence so a killed app does not lose the form.
  void _persistDraft() {
    _trace.step('cache', 'local draft saved',
        {'step': '${state.currentStep.number}/5'});
    _repository.saveDraft(state.draft);
  }
}

/// A step that failed validation, with the reasons.
class _BlockedStep {
  const _BlockedStep(this.step, this.errors);
  final BpFormStep step;
  final Map<String, String> errors;
}
