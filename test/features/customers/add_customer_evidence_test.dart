import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/sap_reference_options.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_datasources.dart';
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

class _MockDocuments extends Mock implements CustomerDocumentRepository {}

void main() {
  late _MockRegistration registration;
  late _MockDocuments documents;

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

  /// Puts the bloc in the state `_onSubmit` expects: a server draft is open.
  Future<void> openDraft(AddCustomerBloc bloc) async {
    bloc.add(const OpenServerDraft());
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    registration = _MockRegistration();
    documents = _MockDocuments();

    when(() => registration.openDraft())
        .thenAnswer((_) async => OpenedRegistrationDraft(
              draft: const CustomerRegistrationDraft(
                  draftId: 'draft-1', fields: {}),
              resumed: false,
            ));
    when(() => registration.loadReferenceOptions())
        .thenAnswer((_) async => SapReferenceOptions.empty);
    when(() => registration.updateServerDraft(
            draftId: any(named: 'draftId'),
            changedFields: any(named: 'changedFields')))
        .thenAnswer((_) async =>
            const CustomerRegistrationDraft(draftId: 'draft-1', fields: {}));
    when(() => registration.submitServerDraft(any())).thenAnswer(
        (_) async => const BusinessPartnerSubmitResult(localId: 'customer-1'));
    when(() => registration.clearDraft()).thenAnswer((_) async {});
  });

  group('uploading after submit', () {
    test('the customer is created before any photograph is sent', () async {
      final order = <String>[];
      when(() => registration.submitServerDraft(any())).thenAnswer((_) async {
        order.add('submit');
        return const BusinessPartnerSubmitResult(localId: 'customer-1');
      });
      when(() => documents.uploadAll(
          customerId: any(named: 'customerId'),
          documents: any(named: 'documents'))).thenAnswer((_) async {
        order.add('upload');
        return const Success(CustomerDocumentUploadOutcome());
      });

      final bloc = build();
      await openDraft(bloc);
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
          documents: any(named: 'documents'))).thenAnswer((invocation) async {
        sent = invocation.namedArguments[#documents]
            as List<PendingCustomerDocument>;
        return const Success(CustomerDocumentUploadOutcome());
      });

      final bloc = build();
      await openDraft(bloc);
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
              documents: any(named: 'documents')))
          .thenAnswer((_) async => const Success(CustomerDocumentUploadOutcome(
                uploaded: [CustomerDocumentType.storefront],
                rejected: [CustomerDocumentType.idCard],
              )));

      final bloc = build();
      await openDraft(bloc);
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
              documents: any(named: 'documents')))
          .thenAnswer((_) async => const Success(CustomerDocumentUploadOutcome(
                uploaded: [CustomerDocumentType.storefront],
              )));

      final bloc = build();
      await openDraft(bloc);
      bloc.add(const SubmitToHQ());
      final state = await bloc.stream
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);

      expect(state.status, AddCustomerStatus.success);
      expect(state.unsentDocuments, isEmpty);
      await bloc.close();
    });

    test('a queued registration keeps the photos on the device', () async {
      // No server-side customer yet, so there is no id worth uploading against.
      when(() => registration.submitServerDraft(any())).thenAnswer((_) async =>
          const BusinessPartnerSubmitResult(localId: '', queuedOffline: true));

      final bloc = build();
      await openDraft(bloc);
      bloc.add(const SubmitToHQ());
      final state = await bloc.stream
          .firstWhere((s) => s.status != AddCustomerStatus.submitting);

      expect(state.status, AddCustomerStatus.success);
      expect(state.queuedOffline, isTrue);
      verifyNever(() => documents.uploadAll(
          customerId: any(named: 'customerId'),
          documents: any(named: 'documents')));
      await bloc.close();
    });
  });
}
