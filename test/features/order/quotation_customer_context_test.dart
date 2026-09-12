import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_builder_screen.dart';

/// Which account the quotation is priced and promoted against.
///
/// This is a regression test with a specific shape behind it. Several entry
/// points open the builder for a shop the rep has already chosen — the
/// customer card's "create quotation", the checked-in visit flow, the
/// Continue-Working resume — and hold the customer's id without having loaded
/// the whole [Customer]. They passed it as `leadId`, the only slot that
/// existed, so anything reading `customer?.id` saw null and served a rep
/// standing in a known shop as though it were a walk-in: no price on any card
/// and no promotion, with the id sitting in the arguments the whole time.
void main() {
  group('the customer context is found however it was supplied', () {
    test('from a fully loaded customer', () {
      final screen = QuotationBuilderScreen(customer: customerFixture());
      expect(screen.customerContextId, 'cust_1');
    });

    test('from the id alone, which is all several callers have', () {
      const screen = QuotationBuilderScreen(customerId: 'cust_1');
      expect(screen.customerContextId, 'cust_1');
    });

    test('the loaded customer wins when both are given', () {
      // Both are passed on the resume path. They name the same shop; the
      // loaded record is the more authoritative of the two.
      final screen = QuotationBuilderScreen(
        customer: customerFixture(),
        customerId: 'stale_id',
      );
      expect(screen.customerContextId, 'cust_1');
    });
  });

  group('a lead is not a customer', () {
    test('a lead id is never used as the pricing customer', () {
      // A lead is an unregistered shop with no SAP account. Sending its id to
      // `/pricing/customers/{id}` would 404 and render as "customer not
      // found" — an error, where the honest answer is that there is nobody to
      // price for yet.
      const screen = QuotationBuilderScreen(leadId: 'lead_9');
      expect(screen.customerContextId, isNull);
    });

    test('a genuine walk-in has no context at all', () {
      const screen = QuotationBuilderScreen();
      expect(screen.customerContextId, isNull);
    });

    test('a customer opened via the lead slot is still found', () {
      // The exact shape of the bug: `openQuotationForCustomer` passes the
      // customer id through `leadId` for the cart, and now through
      // `customerId` as well so pricing sees it.
      const screen = QuotationBuilderScreen(
        customerId: 'cust_1',
        leadId: 'cust_1',
      );
      expect(screen.customerContextId, 'cust_1');
    });
  });
}

/// Keeps the `Customer` construction out of the assertions above.
Customer customerFixture() => Customer(
      id: 'cust_1',
      customerCode: 'C-0001',
      shopName: 'Sok Heng Hardware',
      ownerName: 'Sok',
      phone: '012345678',
      address: 'Street 271',
      province: 'Phnom Penh',
      district: 'Chamkar Mon',
      territory: 'T1',
      latitude: 11.55,
      longitude: 104.92,
      creditLimit: 50000,
      status: CustomerStatus.active,
      assignedRepId: 'rep_1',
      assignedRepName: 'Mengchou CHORN',
      updatedAt: DateTime(2026, 1, 1),
    );
