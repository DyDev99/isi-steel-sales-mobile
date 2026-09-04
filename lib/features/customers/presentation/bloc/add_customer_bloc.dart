// =============================================================================
// add_customer_bloc.dart
//
// The whole form is ONE object (BpCustomerDraft) instead of an event per
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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/logging/debug_trace.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/sap_reference_options.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/business_partner_request.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_document.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_submit_progress.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/business_partner_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_document_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/business_partner_submission.dart';

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

/// Loads the reference catalogues and any saved form.
///
/// Named `OpenForm` rather than the old `OpenServerDraft` because nothing
/// server-side is opened any more. Both steps degrade rather than fail, so
/// unlike its predecessor this event cannot leave the form unusable.
class OpenForm extends AddCustomerEvent {
  const OpenForm();
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

/// Asks SAP whether the form would be accepted, without creating anything.
///
/// Optional and rep-triggered. It costs a round trip, and the rep is the only
/// one who knows whether the connection in this shop can afford one.
class ValidateWithSap extends AddCustomerEvent {
  const ValidateWithSap();
}

class SubmitToHQ extends AddCustomerEvent {
  const SubmitToHQ();
}

/// Throws away the saved form and starts blank. Reachable from the resume
/// banner — a rep who is registering a different shop must be able to say so.
class DiscardDraft extends AddCustomerEvent {
  const DiscardDraft();
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------
enum AddCustomerStatus {
  opening,
  editing,
  validating,
  submitting,
  success,
  failure,
}

class AddCustomerState {
  final BpFormStep currentStep;
  final BpCustomerDraft draft;
  final AddCustomerStatus status;

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
  final String? customerNumber;

  /// True when the registration was stored and is waiting on HQ approval
  /// rather than already numbered in SAP.
  ///
  /// The rep needs to be told which of the two happened: "sent for approval"
  /// and "customer 0000123456 created" are different promises, and showing the
  /// second when the first is true is how a rep comes to expect they can order
  /// against the shop today.
  final bool awaitingApproval;

  /// True when a `Commit: false` dry run last came back clean. Reset by any
  /// subsequent edit, because a form that has changed since the dry run has
  /// not been validated.
  final bool sapPreCheckPassed;

  /// Evidence slots that did not reach the server, if any.
  ///
  /// The registration still succeeded — a customer is never lost to a
  /// photograph — so this is reported alongside success rather than as a
  /// failure the rep has to clear before continuing.
  final List<CustomerDocumentType> unsentDocuments;

  /// How far a submit has got. Drives the progress dialog; meaningless unless
  /// [status] is [AddCustomerStatus.submitting].
  final CustomerSubmitProgress progress;

  /// ERP catalogues backing the SAP-code dropdowns.
  ///
  /// Defaults to [SapReferenceOptions.empty], which resolves every dropdown to
  /// the built-in list — so the form is usable before (and without) a
  /// successful reference load.
  final SapReferenceOptions references;

  const AddCustomerState({
    required this.currentStep,
    required this.draft,
    this.status = AddCustomerStatus.editing,
    this.errors = const {},
    this.errorMessage,
    this.queuedOffline = false,
    this.resumedDraft = false,
    this.customerNumber,
    this.awaitingApproval = false,
    this.sapPreCheckPassed = false,
    this.references = SapReferenceOptions.empty,
    this.progress = const CustomerSubmitProgress(),
    this.unsentDocuments = const [],
  });

  bool get isFirstStep => currentStep.index == 0;
  bool get isLastStep => currentStep.index == BpFormStep.values.length - 1;

  /// True while a network call owns the form and input must be inert.
  bool get isBusy =>
      status == AddCustomerStatus.opening ||
      status == AddCustomerStatus.validating ||
      status == AddCustomerStatus.submitting;

  /// NOTE: deliberately NOT Equatable. The draft is mutable, so value equality
  /// would swallow edits. Every emit creates a new instance, and identity
  /// comparison makes bloc rebuild every time.
  AddCustomerState copyWith({
    BpFormStep? currentStep,
    BpCustomerDraft? draft,
    AddCustomerStatus? status,
    Map<String, String>? errors,
    String? errorMessage,
    bool? queuedOffline,
    bool? resumedDraft,
    String? customerNumber,
    bool? awaitingApproval,
    bool? sapPreCheckPassed,
    SapReferenceOptions? references,
    CustomerSubmitProgress? progress,
    List<CustomerDocumentType>? unsentDocuments,
  }) {
    return AddCustomerState(
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
      status: status ?? this.status,
      errors: errors ?? const {},
      errorMessage: errorMessage,
      queuedOffline: queuedOffline ?? this.queuedOffline,
      resumedDraft: resumedDraft ?? this.resumedDraft,
      customerNumber: customerNumber ?? this.customerNumber,
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

class AddCustomerBloc extends Bloc<AddCustomerEvent, AddCustomerState> {
  final BusinessPartnerRepository _repository;
  final CustomerDocumentRepository _documents;
  final BusinessPartnerSubmission _submission;
  final RepSalesContext _rep;

  AddCustomerBloc({
    required BusinessPartnerRepository repository,
    required CustomerDocumentRepository documents,
    required BusinessPartnerSubmission submission,
    required RepSalesContext rep,
    BpCustomerDraft? initialDraft,
  })  : _repository = repository,
        _documents = documents,
        _submission = submission,
        _rep = rep,
        super(AddCustomerState(
          currentStep: BpFormStep.identity,
          draft: initialDraft ?? BpCustomerDraft(),
        )) {
    _trace.begin('customer registration');
    _trace.step('form', 'opened', {'step': '1/5 identity'});
    on<OpenForm>(_onOpenForm);
    on<DraftChanged>(_onDraftChanged);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<AttachmentAdded>(_onAttachmentAdded);
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

  Future<void> _onOpenForm(
      OpenForm event, Emitter<AddCustomerState> emit) async {
    emit(state.copyWith(status: AddCustomerStatus.opening));

    // Neither call throws by contract, so there is no try/catch and no path
    // where the form fails to open. That is the behavioural difference from
    // the old `OpenServerDraft`, which could and did leave the rep on an
    // error screen with no way forward.
    final saved = await _repository.loadDraft();
    final references = await _repository.loadReferenceOptions();

    final draft = saved ?? state.draft;
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
      status: AddCustomerStatus.editing,
      resumedDraft: saved != null,
      references: references,
    ));
  }

  Future<void> _onDiscardDraft(
      DiscardDraft event, Emitter<AddCustomerState> emit) async {
    await _repository.clearDraft();
    _trace.step('draft', 'discarded by rep');
    emit(AddCustomerState(
      currentStep: BpFormStep.identity,
      draft: BpCustomerDraft(),
      references: state.references,
    ));
  }

  // ---------------------------------------------------------------------
  // Editing
  // ---------------------------------------------------------------------

  void _onDraftChanged(DraftChanged event, Emitter<AddCustomerState> emit) {
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

  void _onNextStep(NextStep event, Emitter<AddCustomerState> emit) {
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

    // No network call. `Next` used to flush a patch and await the response,
    // which made advancing a step fail in a dead spot.
    emit(state.copyWith(
      currentStep: BpFormStep.values[state.currentStep.index + 1],
      status: AddCustomerStatus.editing,
    ));
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

  // ---------------------------------------------------------------------
  // Validate
  // ---------------------------------------------------------------------

  Future<void> _onValidateWithSap(
      ValidateWithSap event, Emitter<AddCustomerState> emit) async {
    final blocked = _firstIncompleteStep();
    if (blocked != null) {
      emit(state.copyWith(
        currentStep: blocked.step,
        errors: blocked.errors,
      ));
      return;
    }

    emit(state.copyWith(status: AddCustomerStatus.validating));
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
          status: AddCustomerStatus.editing,
          sapPreCheckPassed: true,
        ));
      case BpSubmissionRejected(:final message, :final step):
        _trace.fail('precheck', 'SAP would reject', const {});
        emit(state.copyWith(
          status: AddCustomerStatus.editing,
          errorMessage: message,
          currentStep: step ?? state.currentStep,
        ));
      case BpSubmissionUnreachable(:final message):
        // Not a failure of the form. The rep can still submit, which will
        // queue if the connection is still down.
        _trace.warn('precheck', 'unreachable', const {});
        emit(state.copyWith(
          status: AddCustomerStatus.editing,
          errorMessage: message,
        ));
    }
  }

  // ---------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------

  Future<void> _onSubmit(
      SubmitToHQ event, Emitter<AddCustomerState> emit) async {
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

    emit(state.copyWith(
      status: AddCustomerStatus.submitting,
      progress: const CustomerSubmitProgress(stage: SubmitStage.registering),
    ));

    final outcome = await _submission.submit(
      state.draft,
      rep: _rep,
      priceGroupResolver: state.references.priceGroupFor,
    );

    switch (outcome) {
      case BpSubmissionCreated(
          :final customerNumber,
          :final documentId,
          :final isPendingApproval,
        ):
        _trace.ok('submit', isPendingApproval ? 'awaiting HQ' : 'accepted', {
          'customer': DebugTrace.id(customerNumber),
          'record': DebugTrace.id(documentId),
        });

        // Evidence goes up only now: the documents endpoint is addressed by
        // customer id, which did not exist until this moment.
        //
        // Addressed by `documentId`, not the SAP number. A record awaiting HQ
        // approval has no SAP number, and passing the empty string here made
        // `_uploadEvidence` treat every pending registration as having no
        // customer to attach to — so the photographs were held on the device
        // for a record that could perfectly well accept them.
        final photos = state.draft.attachments.length;
        if (photos > 0) {
          emit(state.copyWith(
            progress: CustomerSubmitProgress(
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
          status: AddCustomerStatus.success,
          progress: state.progress.copyWith(stage: SubmitStage.finishing),
          customerNumber: customerNumber,
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
          status: AddCustomerStatus.failure,
          errorMessage: message,
          currentStep: step ?? state.currentStep,
        ));

      case BpSubmissionUnreachable(:final message, :final mayHaveLanded):
        // The draft stays on the device on purpose. There is no offline
        // submission queue for this endpoint yet, so the rep's work is
        // preserved as a resumable form rather than silently dropped — see
        // the note in customers_injection.dart.
        await _repository.saveDraft(state.draft);
        _trace.warn('submit', mayHaveLanded ? 'unknown' : 'held', const {});
        emit(state.copyWith(
          status: AddCustomerStatus.failure,
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

  /// Uploads the captured photographs against the newly created customer.
  ///
  /// Returns the slots that did not make it. **Never throws**: the customer has
  /// already been created, and letting a photograph fail the registration would
  /// lose a shop the rep is standing in for a reason unrelated to it. The
  /// server blocks HQ approval on its own `isComplete` instead
  /// (`docs/feature/customer/mobile/customer-documents.md` §The checklist).
  Future<List<CustomerDocumentType>> _uploadEvidence(
    String customerId,
    bool queuedOffline, {
    void Function(int completed, int total)? onPhotoProgress,
  }) async {
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
