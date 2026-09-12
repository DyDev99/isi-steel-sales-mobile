import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/portal_customer.dart';

/// Parses the **portal** customer shape returned by
/// `GET /customers/by-code/{code}`.
///
/// Kept well away from [CustomerApiMapper]: the field names and the envelope
/// both differ, and the integration guide is explicit that one parser must not
/// serve both surfaces. Every field is read defensively — this is a lookup on a
/// surface the mobile app is a secondary consumer of, so an unexpected null
/// must degrade rather than throw.
abstract final class PortalCustomerMapper {
  static PortalCustomer fromJson(DataMap json) {
    // Flat on the mobile surface, nested here.
    final address =
        (json['address'] as Map?)?.cast<String, dynamic>() ?? const {};

    return PortalCustomer(
      id: json['id']?.toString() ?? '',
      // `code`, not `customerCode`.
      code: json['code'] as String? ?? '',
      // `name`, not `shopName`, and not localised.
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'Draft',
      // Computed server-side as `status == Active`. Used as sent rather than
      // re-derived, so the two can never disagree.
      canTrade: json['canTrade'] as bool? ?? false,
      type: json['type'] as String?,
      phone: json['phone'] as String?,
      city: address['city'] as String?,
      latitude: (address['latitude'] as num?)?.toDouble(),
      longitude: (address['longitude'] as num?)?.toDouble(),
      // A bare decimal on this surface, not `{ amount, currency }`.
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      creditTermDays: (json['creditTermDays'] as num?)?.toInt(),
      assignedSalesRepId: json['assignedSalesRepId'] as String?,
      createdAt: parseUtc(json['createdAt']),
    );
  }

  /// Unwraps the portal envelope, which is `{ data, meta }` — **no `success`
  /// and no `message`**, so [ApiEnvelope] cannot be reused here.
  static PortalCustomer? fromEnvelope(Object? body) {
    if (body is! Map) return null;
    final data = body['data'];
    if (data is! Map) return null;
    final customer = fromJson(data.cast<String, dynamic>());
    // An empty id means the row came back unusable; treat it as absent rather
    // than handing the UI a customer it cannot open.
    return customer.id.isEmpty ? null : customer;
  }
}
