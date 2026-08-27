import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/domain/entities/geo_address.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/domain/entities/geo_unit.dart';

void main() {
  group('BpCustomerDraft address step validation', () {
    test('requires province, district, commune, postal code and gps', () {
      final draft = BpCustomerDraft();
      final errors = draft.validateStep(BpFormStep.address);

      expect(errors['city'], 'error.required');
      expect(errors['district'], 'error.required');
      expect(errors['commune'], 'error.required');
      expect(errors['postalCode'], 'error.postal_5_digits');
      expect(errors['geo'], 'error.gps_required');
    });

    test('accepts a valid gazetteer address with 6-digit postal code and cambodia gps fix', () {
      final draft = BpCustomerDraft(
        cityCode: '12',
        districtCode: '1201',
        communeCode: '120101',
        postalCode: '120101',
        geoFix: GeoFix(
          latitude: 11.5564,
          longitude: 104.9282,
          capturedAt: DateTime.now(),
        ),
      );

      final errors = draft.validateStep(BpFormStep.address);
      expect(errors, isEmpty);
    });

    test('rejects gps outside Cambodia', () {
      final draft = BpCustomerDraft(
        cityCode: '12',
        districtCode: '1201',
        communeCode: '120101',
        postalCode: '12010',
        geoFix: GeoFix(
          latitude: 37.7749, // San Francisco
          longitude: -122.4194,
          capturedAt: DateTime.now(),
        ),
      );

      final errors = draft.validateStep(BpFormStep.address);
      expect(errors['geo'], 'error.gps_outside_kh');
    });

    test('satisfies commune requirement when geoAddress has commune entity', () {
      final draft = BpCustomerDraft(
        cityCode: '12',
        districtCode: '1201',
        postalCode: '12010',
        geoAddress: GeoAddress(
          province: const GeoUnit(
            level: GeoLevel.province,
            code: '12',
            name: LocalizedText(en: 'Phnom Penh', km: 'ភ្នំពេញ'),
            unit: 'Capital',
          ),
          district: const GeoUnit(
            level: GeoLevel.district,
            code: '1201',
            name: LocalizedText(en: 'Chamkar Mon', km: 'ចំការមន'),
            unit: 'Khan',
          ),
          commune: const GeoUnit(
            level: GeoLevel.commune,
            code: '120101',
            name: LocalizedText(en: 'Tonle Basak', km: 'ទន្លេបាសាក់'),
            unit: 'Sangkat',
            postalCode: '120101',
          ),
        ),
        geoFix: GeoFix(
          latitude: 11.5564,
          longitude: 104.9282,
          capturedAt: DateTime.now(),
        ),
      );

      final errors = draft.validateStep(BpFormStep.address);
      expect(errors, isEmpty);
    });
  });

  group('BpCustomerDraft server fields and payload mapping', () {
    test('parses commune and village from server fields', () {
      final draft = BpCustomerDraft();
      draft.applyServerFields({
        'city': '12',
        'district': '1201',
        'commune': '120101',
        'village': '12010101',
        'postalCode': '12010',
        'deliveryPriority': '01',
        'shippingCondition': '02',
        'contactPersonName': 'John Doe',
        'contactPersonRole': '01',
      });

      expect(draft.cityCode, '12');
      expect(draft.districtCode, '1201');
      expect(draft.communeCode, '120101');
      expect(draft.villageCode, '12010101');
      expect(draft.postalCode, '12010');
      expect(draft.deliveryPriority, '01');
      expect(draft.shippingCondition, '02');
      expect(draft.contactPersonName, 'John Doe');
      expect(draft.contactPersonRole, '01');
    });

    test('toSapPayload includes city, district, commune, village, sales terms and contact', () {
      final draft = BpCustomerDraft(
        street: 'Street 271',
        houseNumber: '217',
        cityCode: '12',
        districtCode: '1201',
        communeCode: '120101',
        villageCode: '12010101',
        postalCode: '12010',
        deliveryPriority: '01',
        shippingCondition: '02',
        contactPersonName: 'John Doe',
        contactPersonRole: '01',
      );

      const rep = RepSalesContext(
        salesOrganization: '0001',
        salesOrganizationName: 'Phnom Penh ISI',
        salesOffice: '0001',
        salesOfficeName: 'Phnom Penh',
        salesEmployeeId: '107576',
        salesEmployeeName: 'Sales Rep',
      );

      final payload = draft.toSapPayload(rep);
      expect(payload['city'], '12');
      expect(payload['district'], '1201');
      expect(payload['commune'], '120101');
      expect(payload['village'], '12010101');
      expect(payload['street'], 'Street 271');
      expect(payload['houseNo'], '217');
      expect(payload['postalCode'], '12010');
      expect(payload['deliveryPriority'], '01');
      expect(payload['shippingCondition'], '02');
      expect(payload['contactPersonName'], 'John Doe');
      expect(payload['contactPersonRole'], '01');
    });
  });
}
