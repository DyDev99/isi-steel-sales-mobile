import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/sap_reference_options.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/business_partner_request.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/business_partner_result.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_submit_progress.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/business_partner_submission.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_document.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/business_partner_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_document_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/add_customer_bloc.dart';
import 'package:mocktail/mocktail.dart';

/// Evidence photographs are uploaded **after** the customer exists.
///
/// They cannot go earlier: the documents endpoint is addressed by customer id,
/// and no id exists until submit returns one. The consequence that matters is
/// the ordering guarantee — the customer is created first, so a photograph
/// that fails to upload can never cost the rep the registration.
class _MockRegistration extends Mock implements BusinessPartnerRepository {}

class _MockSubmission extends Mock implements BusinessPartnerSubmission {}

/// The bloc only carries the request through to the draft store on an
/// unreachable submit; it never reads a field, so a Fake avoids constructing
/// forty required SAP properties to prove that.
class _FakeRequest extends Fake implements BusinessPartnerRequest {}

class _MockDocuments extends Mock implements CustomerDocumentRepository {}

void main() {
  late _MockRegistration registration;
  late _MockDocuments documents;
  late _MockSubmission submission;

  setUpAll(() {
    registerFallbackValue(<PendingCustomerDocument>[]);
  });

  /// A draft that passes every step, so `_onSubmit` reaches the upload.
  BpCustomerDraft completeDraft() {
    final draft = BpCustomerDraft(
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
      customerGroup: '01',
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

  AddCustomerBloc build({BpCustomerDraft? draft}) => AddCustomerBloc(
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

    registerFallbackValue(BpCustomerDraft());
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
            customerNumber: '6100001234',
            localId: 'customer-1',
            status: BpSubmissionStatus.created,
          ),
        ));
  });

  group('uploading after submit', () {
    test('the customer is created before any photograph is sent', () async {
      final order = <String>[];
      when(() => submission.submit(
            any(),
            rep: any(named: 'rep'),
            priceGroupResolver: any(named: 'priceGroupResolver'),
          )).thenAnswer((_) async {
        order.add('submit');
        return const BpSubmissionCreated(BusinessPartnerResult(
          customerNumber: '6100001234',
          localId: 'customer-1',
          status: BpSubmissionStatus.created,
        ));
      });
      when(() => documents.uploadAll(
          customerId: any(named: 'customerId'),
          documents: any(named: 'documents'),
          onProgress: any(named: 'onProgress'))).thenAnswer((_) async {
        order.add('upload');
        return const Success(CustomerDocumentUploadOutcome());
      });

      final bloc = build();
      bloc.add(const SubmitToHQ());
      await bloc.stream
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);

      expect(order, ['submit', 'upload'],
          reason: 'the documents endpoint is addressed by customer id, which '
              'does not exist until submit returns');
      await bloc.close();
    });

    test('each captured photo maps to its API slot', () async {
      List<PendingCustomerDocument>? sent;
      when(() => documents.uploadAll(
          customerId: any(named: 'customerId'),
          documents: any(named: 'documents'),
          onProgress: any(named: 'onProgress'))).thenAnswer((invocation) async {
        sent = invocation.namedArguments[#documents]
            as List<PendingCustomerDocument>;
        return const Success(CustomerDocumentUploadOutcome());
      });

      final bloc = build();
      bloc.add(const SubmitToHQ());
      await bloc.stream
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);

      expect(sent, isNotNull);
      expect(sent!.map((d) => d.type), [
        CustomerDocumentType.storefront,
        CustomerDocumentType.insideStore,
        CustomerDocumentType.idCard,
      ]);
      // Photo time, not upload time.
      expect(sent!.first.capturedAt, DateTime.utc(2026, 8, 31, 8));
      await bloc.close();
    });

    test('a failed photo still leaves the registration successful', () async {
      when(() => documents.uploadAll(
              customerId: any(named: 'customerId'),
              documents: any(named: 'documents'),
              onProgress: any(named: 'onProgress')))
          .thenAnswer((_) async => const Success(CustomerDocumentUploadOutcome(
                uploaded: [CustomerDocumentType.storefront],
                rejected: [CustomerDocumentType.idCard],
              )));

      final bloc = build();
      bloc.add(const SubmitToHQ());
      final state = await bloc.stream
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);

      expect(state.status, AddCustomerStatus.success,
          reason: 'a customer must never be lost to a photograph');
      // ...but the rep is told, rather than believing it was filed.
      expect(state.unsentDocuments, [CustomerDocumentType.idCard]);
      await bloc.close();
    });

    test('a clean run reports nothing outstanding', () async {
      when(() => documents.uploadAll(
              customerId: any(named: 'customerId'),
              documents: any(named: 'documents'),
              onProgress: any(named: 'onProgress')))
          .thenAnswer((_) async => const Success(CustomerDocumentUploadOutcome(
                uploaded: [CustomerDocumentType.storefront],
              )));

      final bloc = build();
      bloc.add(const SubmitToHQ());
      final state = await bloc.stream
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);

      expect(state.status, AddCustomerStatus.success);
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
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);

      expect(state.status, AddCustomerStatus.failure);
      expect(state.queuedOffline, isTrue);
      verifyNever(() => documents.uploadAll(
          customerId: any(named: 'customerId'),
          documents: any(named: 'documents'),
          onProgress: any(named: 'onProgress')));
      await bloc.close();
    });
  });

  group('submit progress', () {
    test('advances through the real stages, ending on finishing', () async {
      when(() => documents.uploadAll(
            customerId: any(named: 'customerId'),
            documents: any(named: 'documents'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((invocation) async {
        // Report each photo landing, as the real repository does.
        final report =
            invocation.namedArguments[#onProgress] as void Function(int, int)?;
        for (var i = 1; i <= 3; i++) {
          report?.call(i, 3);
        }
        return const Success(CustomerDocumentUploadOutcome());
      });

      final bloc = build();
      final seen = <CustomerSubmitProgress>[];
      final sub = bloc.stream.listen((s) => seen.add(s.progress));

      bloc.add(const SubmitToHQ());
      await bloc.stream
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);
      await sub.cancel();

      final stages = seen.map((p) => p.stage).toSet();
      expect(stages, contains(SubmitStage.registering));
      expect(stages, contains(SubmitStage.uploadingPhotos));
      expect(seen.last.stage, SubmitStage.finishing);
    });

    test('the photo counter reaches the total', () async {
      when(() => documents.uploadAll(
            customerId: any(named: 'customerId'),
            documents: any(named: 'documents'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((invocation) async {
        final report =
            invocation.namedArguments[#onProgress] as void Function(int, int)?;
        for (var i = 1; i <= 3; i++) {
          report?.call(i, 3);
        }
        return const Success(CustomerDocumentUploadOutcome());
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
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);
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
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);
      await sub.cancel();

      // Validation blocks this draft (photos are required), so the guard is
      // that no upload stage is ever announced for a draft carrying none.
      expect(seen, isNot(contains(SubmitStage.uploadingPhotos)));
    });
  });
}
