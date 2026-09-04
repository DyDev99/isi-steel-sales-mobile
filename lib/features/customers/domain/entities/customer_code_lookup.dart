import 'package:isi_steel_sales_mobile/features/customers/domain/entities/portal_customer.dart';

/// The outcome of a by-code lookup.
///
/// ## Why this is a sealed type and not a nullable customer
///
/// "Not found" and "could not ask" must never be presented the same way, and a
/// `PortalCustomer?` invites exactly that collapse:
///
///  * **404 — the code does not exist.** Safe to offer to register the shop.
///  * **502 — the ERP could not be reached.** The customer may well exist. If
///    the app offers a registration here it creates a **duplicate business
///    partner in SAP**, which is expensive to unpick and invisible until
///    somebody reconciles the ERP.
///
/// Making them separate variants means a caller cannot accidentally treat the
/// second as the first — the switch will not compile until both are handled.
/// See `docs/feature/customer/mobile/mobile.md` §Statuses.
sealed class CustomerCodeLookup {
  const CustomerCodeLookup();
}

/// Found — either locally or fetched from SAP on the server's side. Whatever
/// came back from SAP is stored server-side, so the next lookup is local.
final class CustomerCodeFound extends CustomerCodeLookup {
  const CustomerCodeFound(this.customer);
  final PortalCustomer customer;
}

/// Neither the platform nor SAP has this code (`Customer.NotFoundByCode`).
///
/// **This is the only outcome where offering to register the shop is safe.**
final class CustomerCodeAbsent extends CustomerCodeLookup {
  const CustomerCodeAbsent();
}

/// The ERP could not be reached (502).
///
/// **Never offer to register from here.** Tell the rep it cannot be checked
/// right now and to try again later.
final class CustomerCodeUnavailable extends CustomerCodeLookup {
  const CustomerCodeUnavailable();
}
