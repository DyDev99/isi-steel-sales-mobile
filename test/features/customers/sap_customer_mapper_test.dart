import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/dto/sap_business_partner.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/sap_customer_mapper.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// Pinned to the **captured live** `GetPaging/Live110` response of 2026-07-22 —
/// not to the technical document, which disagrees with the wire on casing
/// (`Rows` vs `rows`), the Khmer-name key (`NameKh` vs `name3`), and the very
/// existence of `Latitude`/`Longitude`.
void main() {
  /// A real row, abridged from the capture (depot with coordinates + block).
  Map<String, dynamic> liveDepotRow() => {
        'Customer': '6100000017',
        'SalesOrg': '0001',
        'SalesOrgName': 'Phnom Penh (ISI)',
        'DistributionChannel': '70',
        'DistributionChannelName': 'Distributor',
        'Division': '10',
        'DivisionName': 'ISI Steel',
        'NameEn': 'PNP-DEPOT REAKSMEY SIEM REAP',
        'NameKh': 'ដេប៉ូ​​​ រស្មី សៀមរាប',
        'PriceGroup': '71',
        'PriceGroupName': 'Distributor',
        'PaymentTerms': 'T045',
        'PaymentTermsName': '45 days due net',
        'CreationDate': '20230312',
        'CustomerGroup': '07',
        'CustomerGroupName': 'Distributor',
        'CoName': 'ISI KEY DEPOT',
        'Latitude': '11.383211',
        'Longitude': '104.863216',
        'Country': 'KH',
        'Region': 'R01',
        'City': 'Kandal',
        'Street': '',
        'Telephone': '089506667',
        'MobilePhone': '',
        'OrderBlock': '',
        'SearchTerm1': 'PHNOM PENH',
        'SearchTerm2': 'IC00011731',
        'SALESBLOCK': 'X',
        'BLOCKFLAG': '',
        'CreditLimit': 200000.00,
        'SalesEmployee': '00103979',
        'SalesEmployeeName': 'SON PHUONG',
      };

  group('SapCustomerPage.fromJson — live PascalCase envelope', () {
    test('parses Page/Rows casing (the regression that hid every customer)',
        () {
      // The first integration read lowercase keys only; against the real
      // server that produced an empty page and a sync that "succeeded" with
      // nothing. This test pins the live casing forever.
      final page = SapCustomerPage.fromJson({
        'Page': 1,
        'PageSize': 50,
        'TotalCount': 6266,
        'TotalPages': 126,
        'Rows': [liveDepotRow()],
      });

      expect(page.totalCount, 6266);
      expect(page.totalPages, 126);
      expect(page.rows, hasLength(1));
      expect(page.hasMore, isTrue);
    });

    test('still accepts the documented camelCase envelope', () {
      final page = SapCustomerPage.fromJson({
        'page': 126,
        'pageSize': 50,
        'totalCount': 6266,
        'totalPages': 126,
        'rows': <Map<String, dynamic>>[],
      });

      expect(page.totalPages, 126);
      expect(page.hasMore, isFalse, reason: 'last page');
    });
  });

  group('SapBusinessPartner.fromJson — live row', () {
    test('reads the live keys', () {
      final bp = SapBusinessPartner.fromJson(liveDepotRow());

      expect(bp.customerNumber, '6100000017');
      expect(bp.nameEn, 'PNP-DEPOT REAKSMEY SIEM REAP');
      expect(bp.nameKh, isNotNull, reason: 'NameKh, not the document\'s name3');
      expect(bp.salesOrgName, 'Phnom Penh (ISI)');
      expect(bp.paymentTermsName, '45 days due net');
      expect(bp.searchTerm2, 'IC00011731');
      expect(bp.parsedFieldCount, greaterThan(10));
    });

    test('string coordinates parse; blanks stay null, never 0.0', () {
      final withCoords = SapBusinessPartner.fromJson(liveDepotRow());
      expect(withCoords.latitude, 11.383211);
      expect(withCoords.longitude, 104.863216);

      final walkIn = SapBusinessPartner.fromJson(
          {'Customer': '6100000000', 'Latitude': '', 'Longitude': ''});
      expect(walkIn.latitude, isNull,
          reason: '"" must not become 0.0 — that is a real place at sea');
      expect(walkIn.longitude, isNull);
    });

    test('CreationDate yyyyMMdd parses; 00000000 means none', () {
      expect(SapBusinessPartner.fromJson(liveDepotRow()).creationDate,
          DateTime.utc(2023, 3, 12));
      expect(
        SapBusinessPartner.fromJson(
                {'Customer': '1', 'CreationDate': '00000000'})
            .creationDate,
        isNull,
      );
    });

    test('any non-empty block field marks the partner blocked', () {
      expect(SapBusinessPartner.fromJson(liveDepotRow()).isBlocked, isTrue,
          reason: 'SALESBLOCK = X');
      expect(
        SapBusinessPartner.fromJson({'Customer': '1', 'BLOCKFLAG': 'X'})
            .isBlocked,
        isTrue,
      );
      expect(
        SapBusinessPartner.fromJson({'Customer': '1', 'OrderBlock': '01'})
            .isBlocked,
        isTrue,
        reason: 'unknown block codes fail safe, not just the X flag',
      );
      expect(
          SapBusinessPartner.fromJson({'Customer': '1'}).isBlocked, isFalse);
    });
  });

  group('toCustomerModel — live semantics', () {
    test('maps a live depot row end to end', () {
      final model =
          SapBusinessPartner.fromJson(liveDepotRow()).toCustomerModel();

      expect(model.id, '6100000017');
      expect(model.customerCode, 'IC00011731',
          reason: 'the legacy code staff recognise, not the BP number');
      expect(model.shopName, 'PNP-DEPOT REAKSMEY SIEM REAP');
      expect(model.territory, 'Phnom Penh (ISI)',
          reason: 'SalesOrgName is this app\'s territory concept');
      expect(model.latitude, 11.383211);
      expect(model.hasCoordinates, isTrue);
      expect(model.paymentTerms, '45 days due net',
          reason: 'display name preferred over the T045 code');
      expect(model.customerGroup, 'Distributor');
      expect(model.salesOrg, '0001', reason: 'codes kept for filters');
      expect(model.phone, '089506667',
          reason: 'Telephone when MobilePhone is blank');
      expect(model.creditLimit, 200000.00);
      expect(model.createdAt, DateTime.utc(2023, 3, 12));
      expect(model.assignedRepName, 'SON PHUONG');
    });

    test('block flags map to creditHold; their absence to active', () {
      // Not a guessed default: with the block fields on the wire, "no block
      // set" is an explicit statement from the ERP.
      expect(
        SapBusinessPartner.fromJson(liveDepotRow()).toCustomerModel().status,
        CustomerStatus.creditHold,
      );
      expect(
        SapBusinessPartner.fromJson({'Customer': '1', 'NameEn': 'X'})
            .toCustomerModel()
            .status,
        CustomerStatus.active,
      );
    });

    test('walk-in row: absent fields stay honest, never sentinel', () {
      final model = SapBusinessPartner.fromJson({
        'Customer': '6100000000',
        'NameEn': 'PNP-Walk In Customer',
        'SearchTerm1': 'PHNOM PENH',
        'Latitude': '',
        'Longitude': '',
        'City': '',
      }).toCustomerModel();

      expect(model.latitude, isNull);
      expect(model.hasCoordinates, isFalse);
      expect(model.province, 'PHNOM PENH',
          reason: 'SearchTerm1 fallback when City is blank');
      expect(model.phone, isEmpty);
      expect(model.ownerName, isEmpty,
          reason: 'no proprietor on the wire; CoName is a channel tag');
    });

    test('id stays the SAP number — stable across repeated syncs', () {
      final a = SapBusinessPartner.fromJson(liveDepotRow()).toCustomerModel();
      final b = SapBusinessPartner.fromJson(liveDepotRow()).toCustomerModel();
      expect(a.id, b.id);
    });
  });

  group('toCustomerModels', () {
    test('drops keyless rows; keeps duplicate customer numbers (last wins '
        'at upsert)', () {
      final models = SapCustomerPage.fromJson({
        'Page': 1,
        'PageSize': 50,
        'TotalCount': 3,
        'TotalPages': 1,
        'Rows': [
          liveDepotRow(),
          liveDepotRow(), // same customer, second sales area — real feed shape
          {'NameEn': 'Keyless'},
        ],
      }).toCustomerModels();

      expect(models, hasLength(2),
          reason: 'keyless dropped; duplicates pass through to the upsert');
      expect(models[0].id, models[1].id);
    });
  });
}
