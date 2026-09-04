import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/domain/entities/geo_address.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/domain/entities/geo_unit.dart';

/// Step 2 of the BP form now captures its address through the shared gazetteer
/// component. These are the seams between the two: what reaches SAP, and what
/// blocks the step.

GeoUnit _u(
  GeoLevel level,
  String code,
  String en, {
  String unit = 'Unit',
  String? postal,
}) =>
    GeoUnit(
      level: level,
      code: code,
      name: LocalizedText(en: en, km: en),
      unit: unit,
      postalCode: postal,
    );

final _address = GeoAddress(
  province: _u(GeoLevel.province, '12', 'Phnom Penh', unit: 'Capital'),
  district: _u(GeoLevel.district, '1201', 'Chamkar Mon', unit: 'Khan'),
  commune: _u(GeoLevel.commune, '120101', 'Tonle Basak',
      unit: 'Sangkat', postal: '120101'),
  village: _u(GeoLevel.village, '12010101', 'Ou Thum', unit: 'Village'),
);

BpCustomerDraft _draft({GeoAddress? address, String street = 'Street 271'}) {
  final a = address ?? _address;
  return BpCustomerDraft(
    nameEn: 'Sok Heng Hardware',
    nameKh: 'ហាង សុខ ហេង',
    street: street,
    houseNumber: '45',
    cityCode: a.province?.code,
    districtCode: a.district?.code,
    communeCode: a.commune?.code,
    villageCode: a.village?.code,
    postalCode: a.postalCode ?? '',
    geoAddress: a,
    geoFix: GeoFix(
      latitude: 11.55,
      longitude: 104.92,
      capturedAt: DateTime.utc(2026, 8, 27),
    ),
    mobilePhone: '012345678',
    contactPersonName: 'Sok',
  );
}

const _rep = RepSalesContext(
  salesOrganization: '1000',
  salesOrganizationName: 'Phnom Penh (ISI)',
  salesOffice: '0001',
  salesOfficeName: 'Phnom Penh',
  salesEmployeeId: '107576',
  salesEmployeeName: 'Mengchou CHORN',
);

void main() {
  group('SAP payload', () {
    test('sends province and district as their own coded fields', () {
      final payload = _draft().toSapPayload(_rep);
      expect(payload['city'], '12');
      expect(payload['district'], '1201');
      expect(payload['postalCode'], '120101');
    });

    test('folds commune and village into street — SAP has no field for them',
        () {
      final payload = _draft().toSapPayload(_rep);
      expect(
          payload['street'], 'Street 271, Phum Ou Thum, Sangkat Tonle Basak');
    });

    test('does not send commune or village as their own keys', () {
      // SAP's BP structure has no such fields; sending them would leave the
      // two levels to be dropped by a middleware that does not model them.
      final payload = _draft().toSapPayload(_rep);
      expect(payload.containsKey('commune'), isFalse);
      expect(payload.containsKey('village'), isFalse);
    });

    test('uses Khum for a commune and Sangkat for a sangkat', () {
      final rural = GeoAddress(
        province: _u(GeoLevel.province, '01', 'Banteay Meanchey'),
        district: _u(GeoLevel.district, '0102', 'Mongkol Borei'),
        commune: _u(GeoLevel.commune, '010201', 'Banteay Neang',
            unit: 'Commune', postal: '010201'),
      );
      final payload = _draft(address: rural).toSapPayload(_rep);
      expect(payload['street'], endsWith('Khum Banteay Neang'));
    });

    test('omits the levels that are not selected', () {
      final partial = GeoAddress(
        province: _address.province,
        district: _address.district,
        commune: _address.commune,
      );
      final payload = _draft(address: partial).toSapPayload(_rep);
      expect(payload['street'], 'Street 271, Sangkat Tonle Basak');
    });

    test('stays within SAP\'s 60-character street field', () {
      final payload = _draft(street: 'A' * 80).toSapPayload(_rep);
      expect((payload['street'] as String).length, lessThanOrEqualTo(60));
    });

    test(
        'keeps the street text when truncating, since it truncates from the '
        'end', () {
      final payload =
          _draft(street: 'National Road 5, Building C').toSapPayload(_rep);
      expect(payload['street'], startsWith('National Road 5, Building C'));
    });
  });

  group('address-step validation', () {
    test('a complete address passes', () {
      expect(_draft().validateStep(BpFormStep.address), isEmpty);
    });

    test('a missing commune blocks the step', () {
      final draft = _draft()
        ..communeCode = null
        ..geoAddress = GeoAddress(
          province: _address.province,
          district: _address.district,
        );
      expect(draft.validateStep(BpFormStep.address), contains('commune'));
    });

    test('a missing district blocks the step', () {
      final draft = _draft()..districtCode = null;
      expect(draft.validateStep(BpFormStep.address), contains('district'));
    });

    test(
        'an undeterminable postal code blocks the step rather than being '
        'guessed from the district', () {
      // The 99 communes Cambodia Post does not cover. The old behaviour filled
      // this from a per-district table holding superseded five-digit codes —
      // a code for a different place.
      final uncovered = GeoAddress(
        province: _address.province,
        district: _address.district,
        commune: _u(GeoLevel.commune, '120199', 'Uncovered', unit: 'Sangkat'),
      );
      final draft = _draft(address: uncovered)..postalCode = '';

      final errors = draft.validateStep(BpFormStep.address);
      expect(errors, contains('postalCode'));
      expect(draft.postalCode, isEmpty,
          reason: 'applyDerivations must not invent one');

      // …and passes once the rep supplies the real code.
      draft.postalCode = '120199';
      expect(draft.validateStep(BpFormStep.address),
          isNot(contains('postalCode')));
    });

    test('applyDerivations no longer touches the postal code', () {
      final draft = _draft()..postalCode = '';
      draft.applyDerivations();
      expect(draft.postalCode, isEmpty);
    });

    test('accepts a six-digit code and still accepts a stored five-digit one',
        () {
      final draft = _draft()..postalCode = '120101';
      expect(draft.validateStep(BpFormStep.address),
          isNot(contains('postalCode')));

      // A draft saved under the superseded scheme must not strand the rep.
      draft.postalCode = '12000';
      expect(draft.validateStep(BpFormStep.address),
          isNot(contains('postalCode')));

      draft.postalCode = '12';
      expect(draft.validateStep(BpFormStep.address), contains('postalCode'));
    });
  });

  group('server draft round trip', () {
    test('restores province, district and postal code from the server fields',
        () {
      final draft = BpCustomerDraft()
        ..applyServerFields({
          'city': '12',
          'district': '1201',
          'postalCode': '120101',
        });

      expect(draft.cityCode, '12');
      expect(draft.districtCode, '1201');
      expect(draft.postalCode, '120101');
    });
  });
}
