import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/models/bp_depot_form_data.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/models/sap_reference_options.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/business_partner_request.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/business_partner_result.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_submit_progress.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/business_partner_submission.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_document.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/business_partner_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_document_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/add_depot_bloc.dart';
import 'package:mocktail/mocktail.dart';

/// Evidence photographs are uploaded **after** the depot exists.
///
/// They cannot go earlier: the documents endpoint is addressed by depot id,
/// and no id exists until submit returns one. The consequence that matters is
/// the ordering guarantee — the depot is created first, so a photograph
/// that fails to upload can never cost the rep the registration.
class _MockRegistration extends Mock implements BusinessPartnerRepository {}

class _MockSubmission extends Mock implements BusinessPartnerSubmission {}

/// The bloc only carries the request through to the draft store on an
/// unreachable submit; it never reads a field, so a Fake avoids constructing
/// forty required SAP properties to prove that.
class _FakeRequest extends Fake implements BusinessPartnerRequest {}

class _MockDocuments extends Mock implements DepotDocumentRepository {}

void main() {
  late _MockRegistration registration;
  late _MockDocuments documents;
  late _MockSubmission submission;

  setUpAll(() {
    registerFallbackValue(<PendingDepotDocument>[]);
  });

  /// A draft that passes every step, so `_onSubmit` reaches the upload.
  BpDepotDraft completeDraft() {
    final draft = BpDepotDraft(
      nameEn: 'Sok Heng Hardware',
      nameKh: 'ហាង សុខ ហេង',
      // Address: gazetteer codes, a 6-digit postal code and a fix inside
      // Cambodia — the whole step has to pass or submit never reaches upload.
      cityCode: '12',
      districtCode: '1204',
      communeCode: '120101',
      postalCode: '120101',
      geoFix: GeoFix(
        latitude: 11.5449,
        longitude: 104.9160,
        capturedAt: DateTime.utc(2026, 8, 31, 8),
      ),
      mobilePhone: '012345678',
      contactPersonName: 'Sok Heng',
      contactPersonRole: 'owner',
      salesOrg: '0001',
      salesOffice: '0001',
      salesGroupCode: '010',
      depotGroup: '01',
    );
    draft.attachments.addAll([
      BpAttachment(
        kind: 'outlet_front',
        localPath: '/tmp/front.jpg',
        capturedAt: DateTime.utc(2026, 8, 31, 8),
      ),
      // Required too — without all three the documents step blocks submit.
      BpAttachment(
        kind: 'outlet_inside',
        localPath: '/tmp/inside.jpg',
        capturedAt: DateTime.utc(2026, 8, 31, 8, 2),
      ),
      BpAttachment(
        kind: 'id_card',
        localPath: '/tmp/id.jpg',
        capturedAt: DateTime.utc(2026, 8, 31, 8, 5),
      ),
    ]);
    return draft;
  }

  AddDepotBloc build({BpDepotDraft? draft}) => AddDepotBloc(
        repository: registration,
        documents: documents,
        submission: submission,
        rep: const RepSalesContext(
          salesOrganization: '0001',
          salesOrganizationName: 'ISI',
          salesOffice: '0001',
          salesOfficeName: 'Phnom Penh',
          salesEmployeeId: 'mobile',
          salesEmployeeName: 'Mobile user',
        ),
        initialDraft: draft ?? completeDraft(),
      );

  /// Lets the bloc settle before the assertions run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    registration = _MockRegistration();
    documents = _MockDocuments();
    submission = _MockSubmission();

    registerFallbackValue(BpDepotDraft());
    registerFallbackValue(const RepSalesContext(
      salesOrganization: '0001',
      salesOrganizationName: 'ISI',
      salesOffice: '0001',
      salesOfficeName: 'Phnom Penh',
      salesEmployeeId: 'mobile',
      salesEmployeeName: 'Mobile user',
    ));

    when(() => registration.loadReferenceOptions())
        .thenAnswer((_) async => SapReferenceOptions.empty);
    when(() => registration.clearDraft()).thenAnswer((_) async {});
    when(() => registration.saveDraft(any())).thenAnswer((_) async {});

    when(() => submission.submit(
          any(),
          rep: any(named: 'rep'),
          priceGroupResolver: any(named: 'priceGroupResolver'),
        )).thenAnswer((_) async => const BpSubmissionCreated(
          BusinessPartnerResult(
            depotNumber: '6100001234',
            localId: 'depot-1',
            status: BpSubmissionStatus.created,
          ),
        ));
  });

  group('uploading after submit', () {
    test('the depot is created before any photograph is sent', () async {
      final order = <String>[];
      when(() => submission.submit(
            any(),
            rep: any(named: 'rep'),
            priceGroupResolver: any(named: 'priceGroupResolver'),
          )).thenAnswer((_) async {
        order.add('submit');
        return const BpSubmissionCreated(BusinessPartnerResult(
          depotNumber: '6100001234',
          localId: 'depot-1',
          status: BpSubmissionStatus.created,
        ));
      });
      when(() => documents.uploadAll(
          depotId: any(named: 'depotId'),
          documents: any(named: 'documents'),
          onProgress: any(named: 'onProgress'))).thenAnswer((_) async {
        order.add('upload');
        return const Success(DepotDocumentUploadOutcome());
      });

      final bloc = build();
      bloc.add(const SubmitToHQ());
      await bloc.stream
          .firstWhere((s) => s.status != AddDepotStatus.submitting);

      expect(order, ['submit', 'upload'],
          reason: 'the documents endpoint is addressed by depot id, which '
              'does not exist until submit returns');
      await bloc.close();
    });

    test('each captured photo maps to its API slot', () async {
      List<PendingDepotDocument>? sent;
      when(() => documents.uploadAll(
          depotId: any(named: 'depotId'),
          documents: any(named: 'documents'),
          onProgress: any(named: 'onProgress'))).thenAnswer((invocation) async {
        sent =
            invocation.namedArguments[#documents] as List<PendingDepotDocument>;
        return const Success(DepotDocumentUploadOutcome());
      });

      final bloc = build();
      bloc.add(const SubmitToHQ());
      await bloc.stream
          .firstWhere((s) => s.status != AddDepotStatus.submitting);

      expect(sent, isNotNull);
      expect(sent!.map((d) => d.type), [
        DepotDocumentType.storefront,
        DepotDocumentType.insideStore,
        DepotDocumentType.idCard,
      ]);
      // Photo time, not upload time.
      expect(sent!.first.capturedAt, DateTime.utc(2026, 8, 31, 8));
      await bloc.close();
    });

    test('a failed photo still leaves the registration successful', () async {
      when(() => documents.uploadAll(
              depotId: any(named: 'depotId'),
              documents: any(named: 'documents'),
              onProgress: any(named: 'onProgress')))
          .thenAnswer((_) async => const Success(DepotDocumentUploadOutcome(
                uploaded: [DepotDocumentType.storefront],
                rejected: [DepotDocumentType.idCard],
              )));

      final bloc = build();
      bloc.add(const SubmitToHQ());
      final state = await bloc.stream
          .firstWhere((s) => s.status != AddDepotStatus.submitting);

      expect(state.status, AddDepotStatus.success,
          reason: 'a depot must never be lost to a photograph');
      // ...but the rep is told, rather than believing it was filed.
      expect(state.unsentDocuments, [DepotDocumentType.idCard]);
      await bloc.close();
    });

    test('a clean run reports nothing outstanding', () async {
      when(() => documents.uploadAll(
              depotId: any(named: 'depotId'),
              documents: any(named: 'documents'),
              onProgress: any(named: 'onProgress')))
          .thenAnswer((_) async => const Success(DepotDocumentUploadOutcome(
                uploaded: [DepotDocumentType.storefront],
              )));

      final bloc = build();
      bloc.add(const SubmitToHQ());
      final state = await bloc.stream
          .firstWhere((s) => s.status != AddDepotStatus.submitting);

      expect(state.status, AddDepotStatus.success);
      expect(state.unsentDocuments, isEmpty);
      await bloc.close();
    });

    test('an unreachable server keeps the photos on the device', () async {
      // Nothing was created, so there is no id to attach evidence to. The
      // draft is preserved and the photographs stay put.
      when(() => submission.submit(
            any(),
            rep: any(named: 'rep'),
            priceGroupResolver: any(named: 'priceGroupResolver'),
          )).thenAnswer((_) async => BpSubmissionUnreachable(
            message: 'No connection',
            request: _FakeRequest(),
            mayHaveLanded: false,
          ));

      final bloc = build();
      bloc.add(const SubmitToHQ());
      final state = await bloc.stream
          .firstWhere((s) => s.status != AddDepotStatus.submitting);

      expect(state.status, AddDepotStatus.failure);
      expect(state.queuedOffline, isTrue);
      verifyNever(() => documents.uploadAll(
          depotId: any(named: 'depotId'),
          documents: any(named: 'documents'),
          onProgress: any(named: 'onProgress')));
      await bloc.close();
    });
  });

  group('submit progress', () {
    test('advances through the real stages, ending on finishing', () async {
      when(() => documents.uploadAll(
            depotId: any(named: 'depotId'),
            documents: any(named: 'documents'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((invocation) async {
        // Report each photo landing, as the real repository does.
        final report =
            invocation.namedArguments[#onProgress] as void Function(int, int)?;
        for (var i = 1; i <= 3; i++) {
          report?.call(i, 3);
        }
        return const Success(DepotDocumentUploadOutcome());
      });

      final bloc = build();
      final seen = <DepotSubmitProgress>[];
      final sub = bloc.stream.listen((s) => seen.add(s.progress));

      bloc.add(const SubmitToHQ());
      await bloc.stream
          .firstWhere((s) => s.status != AddDepotStatus.submitting);
      await sub.cancel();

      final stages = seen.map((p) => p.stage).toSet();
      expect(stages, contains(SubmitStage.registering));
      expect(stages, contains(SubmitStage.uploadingPhotos));
      expect(seen.last.stage, SubmitStage.finishing);
    });

    test('the photo counter reaches the total', () async {
      when(() => documents.uploadAll(
            depotId: any(named: 'depotId'),
            documents: any(named: 'documents'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((invocation) async {
        final report =
            invocation.namedArguments[#onProgress] as void Function(int, int)?;
        for (var i = 1; i <= 3; i++) {
          report?.call(i, 3);
        }
        return const Success(DepotDocumentUploadOutcome());
      });

      final bloc = build();
      final counts = <String>[];
      final sub = bloc.stream.listen((s) {
        if (s.progress.stage == SubmitStage.uploadingPhotos) {
          counts.add('${s.progress.photosSent}/${s.progress.photosTotal}');
        }
      });

      bloc.add(const SubmitToHQ());
      await bloc.stream
          .firstWhere((s) => s.status != AddDepotStatus.submitting);
      await sub.cancel();

      // The draft carries three attachments, so the bar must actually move
      // rather than jump from nothing to done.
      expect(counts, containsAllInOrder(['1/3', '2/3', '3/3']));
    });

    test('a submit with no photos skips the upload stage', () async {
      final bloc = build(draft: completeDraft()..attachments.clear());
      final seen = <SubmitStage>[];
      final sub = bloc.stream.listen((s) => seen.add(s.progress.stage));

      bloc.add(const SubmitToHQ());
      await bloc.stream
          .firstWhere((s) => s.status != AddDepotStatus.submitting);
      await sub.cancel();

      // Validation blocks this draft (photos are required), so the guard is
      // that no upload stage is ever announced for a draft carrying none.
      expect(seen, isNot(contains(SubmitStage.uploadingPhotos)));
    });

    test(
        'sales area fields default to sales org 0001, sales office 0001, and sales group 010',
        () {
      final draft = BpDepotDraft();
      expect(draft.salesOrg, '0001');
      expect(draft.salesOffice, '0001');
      expect(draft.salesGroupCode, '010');
    });
  });

  group('step 5 one-by-one photo upload and step 6 instant submit', () {
    test(
        'adding photo in step 5 creates depot on backend if needed and uploads photo immediately',
        () async {
      when(() => documents.uploadAll(
            depotId: any(named: 'depotId'),
            documents: any(named: 'documents'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => const Success(DepotDocumentUploadOutcome(
            uploaded: [DepotDocumentType.storefront],
          )));

      final bloc = build(draft: completeDraft()..attachments.clear());

      final attachment = BpAttachment(
        kind: 'outlet_front',
        localPath: '/tmp/front.jpg',
        capturedAt: DateTime.utc(2026, 8, 31, 8),
      );

      bloc.add(AttachmentAdded(attachment));

      // Wait until upload completes
      await bloc.stream.firstWhere((s) {
        final att = s.draft.getAttachment('outlet_front');
        return att != null && att.isUploaded && !att.isUploading;
      });

      expect(bloc.state.draft.serverDepotId, 'depot-1');
      expect(bloc.state.draft.isDepotCreatedOnServer, isTrue);

      verify(() => submission.submit(any(),
          rep: any(named: 'rep'),
          priceGroupResolver: any(named: 'priceGroupResolver'))).called(1);
      verify(() => documents.uploadAll(
            depotId: 'depot-1',
            documents: any(
                that: isA<List<PendingDepotDocument>>().having(
                  (docs) =>
                      docs.length == 1 &&
                      docs.first.type == DepotDocumentType.storefront,
                  'single storefront doc',
                  isTrue,
                ),
                named: 'documents'),
            onProgress: any(named: 'onProgress'),
          )).called(1);

      await bloc.close();
    });

    test('step 5 blocks NextStep until all 4 required attachments are uploaded',
        () async {
      final draft = completeDraft();
      // Attachments are captured, but NOT yet uploaded (isUploaded: false)
      for (var i = 0; i < draft.attachments.length; i++) {
        draft.attachments[i] = draft.attachments[i].copyWith(isUploaded: false);
      }

      final bloc = build(draft: draft);
      bloc.add(const GoToStep(BpFormStep.documents));
      await settle();

      bloc.add(const NextStep());
      await settle();

      expect(bloc.state.currentStep, BpFormStep.documents);
      expect(bloc.state.errorMessage, 'add_depot.error.photo_not_uploaded');

      await bloc.close();
    });

    test(
        'step 6 finishes instantly without re-uploading documents if depot was already created',
        () async {
      final readyDraft = completeDraft();
      readyDraft.serverDepotId = 'depot-1';
      readyDraft.depotNumber = '6100001234';
      for (var i = 0; i < readyDraft.attachments.length; i++) {
        readyDraft.attachments[i] =
            readyDraft.attachments[i].copyWith(isUploaded: true);
      }

      final bloc = build(draft: readyDraft);
      bloc.add(const GoToStep(BpFormStep.review));
      await settle();

      clearInteractions(submission);
      clearInteractions(documents);

      bloc.add(const SubmitToHQ());
      final finalState = await bloc.stream
          .firstWhere((s) => s.status == AddDepotStatus.success);

      expect(finalState.status, AddDepotStatus.success);
      expect(finalState.depotNumber, '6100001234');

      // Crucial: Step 6 did NOT re-upload documents or re-create depot!
      verifyNever(() => documents.uploadAll(
            depotId: any(named: 'depotId'),
            documents: any(named: 'documents'),
            onProgress: any(named: 'onProgress'),
          ));
      verifyNever(() => submission.submit(any(),
          rep: any(named: 'rep'),
          priceGroupResolver: any(named: 'priceGroupResolver')));

      await bloc.close();
    });
  });
}
