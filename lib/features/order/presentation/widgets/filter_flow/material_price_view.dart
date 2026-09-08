import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/mobile_price.dart';

/// What this customer pays for one material, as the backend last said it.
///
/// ## Nothing here computes a price
///
/// The amount and the currency are transcribed from `MobilePrice`, which is
/// transcribed from the pricing endpoint. SAP's conditions are not re-derived
/// on the handset and the catalogue figure on `Product.pricing` is never used
/// as a stand-in — a quoted price a customer can hold a rep to has exactly one
/// source, and a plausible local substitute is worse than an honest absence.
///
/// ## Why the states are not collapsed
///
/// "Loading", "this customer has no price for this material" and "the request
/// failed" are three different things a rep has to act on differently: wait,
/// call the office, or retry. Rendering them as one grey dash sends a rep
/// nowhere. Only [PricingState.error] offers a retry — [PricingState.unavailable]
/// is a settled answer from the backend, and retrying asks the same question.
class MaterialPriceView extends StatelessWidget {
  const MaterialPriceView({
    super.key,
    required this.price,
    this.unit,
    this.onRetry,
  });

  /// Null when the screen has no pricing context at all — renders nothing,
  /// which is what keeps the card reusable outside the quotation flow.
  final MobilePrice? price;

  /// The material's selling unit, appended as "/ KG". Identification that
  /// comes off the catalogue row, not from the pricing call.
  final String? unit;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final price = this.price;
    if (price == null) return const SizedBox.shrink();

    if (price.isBusy) return const _PriceLoading();

    if (price.hasAmount) {
      return _PriceAmount(price: price, unit: unit);
    }

    // A price of zero is not a price. `hasAmount` already treats it as absent,
    // because `$0.00` on a quotation is a *quoted price of zero* — a promise a
    // customer can hold the rep to.
    return _PriceMissing(price: price, onRetry: onRetry);
  }
}

/// The figure, plus whether it is still known to be current.
class _PriceAmount extends StatelessWidget {
  const _PriceAmount({required this.price, this.unit});

  final MobilePrice price;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final unit = this.unit?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            formatMaterialPrice(price),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: context.rsp(15),
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        if (unit.isNotEmpty) ...[
          SizedBox(width: context.rw(3)),
          Text(
            '/ $unit',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: context.rsp(11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        SizedBox(width: context.rw(6)),
        // The live dot is the honest half of this widget: it appears only
        // while the price is known to be current, so a figure held over a
        // dropped connection loses the badge rather than keeping a claim
        // nothing is backing.
        if (price.isLive)
          _PriceTag(
            label: 'orders.pricing.live'.tr,
            color: scheme.primary,
            dot: true,
          )
        else
          _PriceTag(
            label: 'orders.pricing.not_live'.tr,
            color: colors.textSecondary,
            dot: false,
          ),
      ],
    );
  }
}

class _PriceLoading extends StatelessWidget {
  const _PriceLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        SizedBox(
          width: context.rr(11),
          height: context.rr(11),
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            color: colors.textSecondary,
          ),
        ),
        SizedBox(width: context.rw(7)),
        Flexible(
          child: Text(
            'orders.pricing.loading'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: context.rsp(11.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// No figure to show — and which of the several reasons it is.
class _PriceMissing extends StatelessWidget {
  const _PriceMissing({required this.price, this.onRetry});

  final MobilePrice price;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final retryable = price.isRetryable && onRetry != null;

    final label = Text(
      _reasonKey(price).tr,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: context.rsp(11.5),
        fontWeight: FontWeight.w600,
      ),
    );

    if (!retryable) return label;

    return InkWell(
      onTap: onRetry,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: label),
          SizedBox(width: context.rw(6)),
          Icon(Icons.refresh_rounded,
              size: context.rr(13), color: scheme.primary),
          SizedBox(width: context.rw(3)),
          Text(
            'orders.pricing.retry'.tr,
            style: TextStyle(
              color: scheme.primary,
              fontSize: context.rsp(11.5),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// The reason, kept distinct rather than flattened to one message.
  ///
  /// "You are offline" sends a rep to find signal, "this customer is not
  /// priceable" sends them to the office, and "unauthorized" sends them to IT.
  /// One generic string sends them nowhere.
  static String _reasonKey(MobilePrice price) => switch (price.errorKind) {
        PricingErrorKind.networkUnavailable => 'orders.pricing.offline',
        PricingErrorKind.backendUnavailable => 'orders.pricing.backend_down',
        PricingErrorKind.unauthorized => 'orders.pricing.unauthorized',
        PricingErrorKind.customerNotFound => 'orders.pricing.no_customer',
        PricingErrorKind.customerNotPriceable => 'orders.pricing.not_priceable',
        PricingErrorKind.noPrice => 'orders.pricing.no_price',
        PricingErrorKind.none => price.state == PricingState.error
            ? 'orders.pricing.unavailable'
            : 'orders.pricing.no_price',
        PricingErrorKind.unknown => 'orders.pricing.unavailable',
      };
}

class _PriceTag extends StatelessWidget {
  const _PriceTag(
      {required this.label, required this.color, required this.dot});

  final String label;
  final Color color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: context.rr(5),
            height: context.rr(5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: context.rw(4)),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: context.rsp(10),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// The amount written in the currency the backend sent with it.
///
/// The currency travels on every item for a reason: a price without it is a
/// number somebody has to remember the currency of. So the symbol is not
/// hardcoded — stamping `$` on a KHR amount would render a figure roughly four
/// thousand times wrong, and it would look entirely plausible.
String formatMaterialPrice(MobilePrice price) {
  final amount = price.price;
  if (amount == null) return '';

  final currency = price.currency.trim().toUpperCase();
  final digits = NumberFormat('#,##0.00').format(amount);

  return switch (currency) {
    'USD' => '\$$digits',
    '' => digits,
    _ => '$digits $currency',
  };
}
