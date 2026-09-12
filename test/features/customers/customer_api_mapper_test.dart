import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_api_mapper.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// A verbatim list row from the guide, used as the happy path.
Map<String, dynamic> _summary() => {
      'id': '019ff532-0000-0000-0000-000000000001',
      'customerCode': 'ISI-PP0005',
      'sapCustomerId': '1000105',
      'shopName': 'ឃ្លាំងសំណង់ ទួលគោក',
      'ownerName': 'Heng Vuthy',
      'phone': '023456005',
      'city': 'Phnom Penh',
      'district': 'Toul Kork',
      'territory': 'PP-NORTH',
      'latitude': 11.5788,
      'longitude': 104.8901,
      'type': 'Distributor',
      'status': 'Active',
      'statusDisplay': 'សកម្ម',
      'canTrade': true,
      'creditLimit': {'amount': 30000.0, 'currency': 'USD'},
      'creditBalance': {'amount': 4200.0, 'currency': 'USD'},
      'lastVisitDate': '2026-08-09T03:12:00Z',
      'lastOrderDate': '2026-08-11T07:45:00Z',
      'assignedRepId': '019fefd2-0000-0000-0000-000000000001',
      'updatedAt': '2026-08-12T02:31:19Z',
      'deleted': false,
    };

void main() {
  group('money', () {
    test('parses the { amount, currency } objects, not bare decimals', () {
      final customer = CustomerApiMapper.fromSummary(_summary());

      expect(customer.creditLimit, 30000.0);
      expect(customer.creditBalance, 4200.0);
      expect(customer.currency, 'USD');
    });
  });

  group('status', () {
    test('branches on the stable code, not the localised label', () {
      // `statusDisplay` here is Khmer. Parsing must not depend on it.
      final customer = CustomerApiMapper.fromSummary(_summary());

      expect(customer.status, CustomerStatus.active);
    });

    test('the full API lifecycle round-trips', () {
      for (final entry in {
        'Draft': CustomerStatus.draft,
        'PendingApproval': CustomerStatus.pendingApproval,
        'Active': CustomerStatus.active,
        'Suspended': CustomerStatus.suspended,
        'Closed': CustomerStatus.closed,
      }.entries) {
        final customer =
            CustomerApiMapper.fromSummary(_summary()..['status'] = entry.key);
        expect(customer.status, entry.value, reason: entry.key);
      }
    });

    test('an unknown status degrades to draft rather than throwing', () {
      // A server that adds a lifecycle state must not crash an older build,
      // and `draft` is the safe default because it is the one state that
      // cannot trade.
      final customer = CustomerApiMapper.fromSummary(
          _summary()..['status'] = 'AwaitingCreditReview');

      expect(customer.status, CustomerStatus.draft);
    });
  });

  group('coordinates', () {
    test('a real fix survives', () {
      final customer = CustomerApiMapper.fromSummary(_summary());

      expect(customer.hasCoordinates, isTrue);
      expect(customer.latitude, closeTo(11.5788, 1e-9));
    });

    test('null coordinates are not a position', () {
      final customer = CustomerApiMapper.fromSummary(_summary()
        ..['latitude'] = null
        ..['longitude'] = null);

      // (0, 0) is how the non-null local schema stores "no fix", so the flag
      // is what callers must consult — never the raw pair.
      expect(customer.hasCoordinates, isFalse);
    });

    test('one coordinate without the other is discarded', () {
      // Latitude and longitude are only ever meaningful together; half a fix
      // is not a location.
      final customer =
          CustomerApiMapper.fromSummary(_summary()..['longitude'] = null);

      expect(customer.hasCoordinates, isFalse);
    });

    test('out-of-range coordinates are rejected', () {
      final customer = CustomerApiMapper.fromSummary(_summary()
        ..['latitude'] = 991.0
        ..['longitude'] = 104.0);

      expect(customer.hasCoordinates, isFalse);
    });
  });

  group('tolerance', () {
    test('a tombstone carrying almost nothing still parses', () {
      // Delta rows for deleted customers are near-empty. Throwing here would
      // abort an entire 200-row sync page over one tombstone.
      final customer = CustomerApiMapper.fromSummary({
        'id': '019ff532-0000-0000-0000-000000000009',
        'deleted': true,
      });

      expect(customer.deleted, isTrue);
      expect(customer.id, '019ff532-0000-0000-0000-000000000009');
    });

    test('a customer with no SAP link maps to null, not empty', () {
      // A draft registered in the field has no SAP identity until HQ links it.
      //
      // This asserted `isEmpty` — the mapper substituted `''` — and that is
      // what broke the sync: the column is UNIQUE, SQLite treats every NULL as
      // distinct but `''` as a single value, so the second such customer threw
      // `UNIQUE constraint failed: customers.sap_customer_id` and aborted the
      // entire batch.
      final customer =
          CustomerApiMapper.fromSummary(_summary()..['sapCustomerId'] = null);

      expect(customer.sapCustomerId, isNull);
    });
  });

  group('timestamps', () {
    test('are parsed as UTC', () {
      final customer = CustomerApiMapper.fromSummary(_summary());

      expect(customer.updatedAt.isUtc, isTrue);
      expect(customer.updatedAt, DateTime.utc(2026, 8, 12, 2, 31, 19));
    });
  });

  group('detail aggregate', () {
    test('reads contacts, the SAP block and the street address', () {
      final customer = CustomerApiMapper.fromDetail(_summary()
        ..['addressLine1'] = 'Street 271, Sangkat Toul Tumpung'
        ..['assignedRepName'] = 'Sok Dara'
        ..['salesOrg'] = '1000'
        ..['lifetimeValue'] = {'amount': 184320.0, 'currency': 'USD'}
        ..['totalOrders'] = 42
        ..['contacts'] = [
          {
            'id': 'c1',
            'name': 'Heng Vuthy',
            'phone': '012345605',
            'position': 'Owner',
            'isPrimary': true,
          },
        ]);

      expect(customer.address, 'Street 271, Sangkat Toul Tumpung');
      expect(customer.assignedRepName, 'Sok Dara');
      expect(customer.salesOrg, '1000');
      expect(customer.lifetimeValue, 184320.0);
      expect(customer.totalOrders, 42);
      expect(customer.contacts.single.name, 'Heng Vuthy');
      // The API calls it `position`; the local model calls it `role`.
      expect(customer.contacts.single.role, 'Owner');
    });

    test('a summary row falls back to district and city for its address', () {
      // The list DTO carries no street address at all — only enough for a list
      // row and a map pin.
      final customer = CustomerApiMapper.fromSummary(_summary());

      expect(customer.address, 'Toul Kork, Phnom Penh');
    });
  });
}
