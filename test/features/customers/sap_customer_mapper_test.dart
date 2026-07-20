import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/dto/sap_business_partner.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/sap_customer_mapper.dart';

/// Covers the SAP business-partner DTO and its mapping onto `CustomerModel`.
///
/// The load-bearing assertions are the *negative* ones: that fields SAP does not
/// supply arrive as null rather than as plausible-looking defaults. A regression
/// there would put every customer at 0°,0° on the map or show a credit-hold
/// account as active — failures that look like data rather than like bugs.
void main() {
  group('SapBusinessPartner.fromJson', () {
    test('parses the documented paging row shape', () {
      final bp = SapBusinessPartner.fromJson(const {
        'customer': '0001000123',
        'nameEn': 'ABC Trading',
        'name1': 'ABC Trading Co., Ltd',
        'street': 'Street 271',
        'city': 'Phnom Penh',
        'country': 'KH',
        'mobilePhone': '012345678',
        'salesOrg': '1000',
        'division': '10',
        'creditLimit': 5000,
        'salesEmployee': 'EMP-1',
      });

      expect(bp.customerNumber, '0001000123');
      expect(bp.nameEn, 'ABC Trading');
      expect(bp.displayName, 'ABC Trading', reason: 'English name preferred');
      expect(bp.creditLimit, 5000);
      expect(bp.formattedAddress, 'Street 271, Phnom Penh, KH');
    });

    test('accepts PascalCase keys', () {
      // The document shows camelCase in examples but names fields in PascalCase
      // in its tables, and the response casing is not pinned down. Both resolve.
      final bp = SapBusinessPartner.fromJson(const {
        'Customer': '0001000999',
        'Name1': 'Pascal Co',
      });

      expect(bp.customerNumber, '0001000999');
      expect(bp.name1, 'Pascal Co');
    });

    test('treats SAP whitespace padding as absent', () {
      // SAP pads fixed-width character fields; "   " must read as unknown, not
      // as a value that renders an unexplained gap in the UI.
      final bp = SapBusinessPartner.fromJson(const {
        'customer': '1',
        'nameEn': '   ',
        'city': '',
      });

      expect(bp.nameEn, isNull);
      expect(bp.city, isNull);
    });

    test('parses a numeric credit limit sent as a string', () {
      final bp = SapBusinessPartner.fromJson(const {
        'customer': '1',
        'creditLimit': '1234.50',
      });

      expect(bp.creditLimit, 1234.50);
    });

    test('counts parsed fields so an unrecognised payload is detectable', () {
      final understood = SapBusinessPartner.fromJson(const {
        'customer': '1',
        'name1': 'X',
        'city': 'PP',
      });
      final unrecognised = SapBusinessPartner.fromJson(const {
        'customer': '1',
        'totally_unexpected_key': 'X',
      });

      expect(understood.parsedFieldCount, greaterThan(0));
      expect(
        unrecognised.parsedFieldCount,
        0,
        reason: 'a payload whose keys match nothing must be visibly empty, '
            'not silently read as a page of blank customers',
      );
    });
  });

  group('SapCustomerPage.fromJson', () {
    test('parses the documented envelope and derives hasMore', () {
      final page = SapCustomerPage.fromJson(const {
        'page': 1,
        'pageSize': 50,
        'totalCount': 1240,
        'totalPages': 25,
        'rows': [
          {'customer': '0001000123', 'nameEn': 'ABC Trading'},
        ],
      });

      expect(page.totalCount, 1240);
      expect(page.rows, hasLength(1));
      expect(page.hasMore, isTrue, reason: 'page 1 of 25');
    });

    test('hasMore is false on the last page', () {
      final page = SapCustomerPage.fromJson(const {
        'page': 25,
        'pageSize': 50,
        'totalCount': 1240,
        'totalPages': 25,
        'rows': <Map<String, dynamic>>[],
      });

      expect(page.hasMore, isFalse);
    });
  });

  group('toCustomerModel', () {
    test('maps the fields SAP does provide', () {
      final model = SapBusinessPartner.fromJson(const {
        'customer': '0001000123',
        'nameEn': 'ABC Trading',
        'street': 'Street 271',
        'city': 'Phnom Penh',
        'mobilePhone': '012345678',
        'creditLimit': 5000,
        'salesEmployee': 'EMP-1',
        'salesEmployeeName': 'Sok Dara',
      }).toCustomerModel();

      expect(model.id, '0001000123');
      expect(model.sapCustomerId, '0001000123');
      expect(model.shopName, 'ABC Trading');
      expect(model.phone, '012345678');
      expect(model.creditLimit, 5000);
      expect(model.assignedRepId, 'EMP-1');
      expect(model.assignedRepName, 'Sok Dara');
    });

    test('leaves SAP-unavailable fields null rather than defaulting them', () {
      final model = SapBusinessPartner.fromJson(const {
        'customer': '0001000123',
        'nameEn': 'ABC Trading',
      }).toCustomerModel();

      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
      expect(model.territory, isNull);
      expect(model.status, isNull);
      expect(model.hasCoordinates, isFalse);
    });

    test('uses the SAP customer number as the local id, not a new UUID', () {
      // Regenerating an id per sync would make every pass insert duplicates
      // instead of updating in place — the upsert is keyed on `id`.
      const json = {'customer': '0001000123', 'nameEn': 'ABC'};
      final first = SapBusinessPartner.fromJson(json).toCustomerModel();
      final second = SapBusinessPartner.fromJson(json).toCustomerModel();

      expect(first.id, second.id);
      expect(first.id, '0001000123');
    });

    test('falls back to the customer number when no name is supplied', () {
      final model = SapBusinessPartner.fromJson(const {'customer': '1'})
          .toCustomerModel();

      expect(model.shopName, '1');
    });

    test('prefers mobilePhone, falling back to telephone', () {
      final mobile = SapBusinessPartner.fromJson(
        const {'customer': '1', 'mobilePhone': '012', 'telephone': '023'},
      ).toCustomerModel();
      final landline = SapBusinessPartner.fromJson(
        const {'customer': '1', 'telephone': '023'},
      ).toCustomerModel();

      expect(mobile.phone, '012');
      expect(landline.phone, '023');
    });
  });

  group('toCustomerModels', () {
    test('drops rows with no customer number', () {
      // A keyless row cannot be upserted or later matched, so importing it would
      // create an orphan that every subsequent sync duplicates.
      final models = SapCustomerPage.fromJson(const {
        'page': 1,
        'pageSize': 50,
        'totalCount': 2,
        'totalPages': 1,
        'rows': [
          {'customer': '0001000123', 'nameEn': 'Real'},
          {'nameEn': 'Keyless'},
        ],
      }).toCustomerModels();

      expect(models, hasLength(1));
      expect(models.single.sapCustomerId, '0001000123');
    });
  });
}
