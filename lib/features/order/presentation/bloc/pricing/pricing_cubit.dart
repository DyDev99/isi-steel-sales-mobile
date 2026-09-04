import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/mobile_price.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/pricing_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_customer_material_prices.dart';

/// Live prices for the materials on this quotation, keyed by material code.
///
/// One entry per material, and that is the whole design: a quotation can
/// legitimately be showing one price live, one loading, one unavailable and
/// one stale at the same time. A screen-level pricing status would make three
/// of those four lie, and one failed material would blank the rest.
///
/// ## The stale-update rule
///
/// A realtime event carries the server's own `updatedAt`. An event older than
/// what is already on screen is **dropped**, never applied. Without that, a
/// delayed packet arriving after a newer one walks the price backwards — and a
/// rep who has already said a number out loud watches it change to an older
/// one for no visible reason.
///
/// ## The reconnect rule
///
/// Hub group membership does not survive a dropped connection, and the hub does
/// not replay what was missed. So a reconnect is not "resume listening": it is
/// re-fetch over REST *and* re-subscribe, in that order. Anything less quotes a
/// price that stopped being current while the socket was down.
class PricingCubit extends Cubit<Map<String, MobilePrice>> {
  PricingCubit({
    required GetCustomerMaterialPrices getPrices,
    required PricingRealtimeSource realtime,
  })  : _getPrices = getPrices,
        _realtime = realtime,
        super(const {}) {
    _updateSub = _realtime.updates.listen(_onRealtimePrice);
    _reconnectSub = _realtime.reconnections.listen((_) => _onReconnected());
  }

  final GetCustomerMaterialPrices _getPrices;
  final PricingRealtimeSource _realtime;

  StreamSubscription<MobilePrice>? _updateSub;
  StreamSubscription<void>? _reconnectSub;

  String? _customerId;

  /// Everything currently on the quotation, so a reconnect knows what to
  /// re-ask for without the UI having to tell it again.
  final Set<String> _tracked = {};

  String? get customerId => _customerId;

  MobilePrice? of(String material) => state[material];

  /// Points pricing at a customer, re-subscribing the hub.
  ///
  /// Changing customer drops every held price: they are quoted *per customer*,
  /// and leaving the previous shop's figures on screen would be both wrong and
  /// a disclosure. The old subscription is dropped before the new one is made,
  /// so the handset never sits in two pricing groups at once.
  Future<void> setCustomer(String? customerId) async {
    if (_customerId == customerId) return;
    _customerId = customerId;
    emit(const {});

    await _realtime.unsubscribe();
    if (customerId == null || customerId.isEmpty) return;
    await _realtime.subscribe(customerId);
    if (_tracked.isNotEmpty) await refresh();
  }

  /// Starts tracking [materials] and fetches any that have no price yet.
  ///
  /// Safe to call whenever the quotation's line-up changes: materials already
  /// priced are not re-asked, so adding an eighth line costs one request for
  /// that line rather than eight for all of them.
  Future<void> track(Iterable<String> materials) async {
    final fresh = materials
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty && !_tracked.contains(m))
        .toSet();
    if (fresh.isEmpty) return;

    _tracked.addAll(fresh);
    await _fetch(fresh.toList());
  }

  /// Stops tracking a material — the line was removed from the quotation.
  void untrack(String material) {
    _tracked.remove(material);
    if (!state.containsKey(material)) return;
    emit({...state}..remove(material));
  }

  /// Re-asks for everything currently tracked.
  ///
  /// The retry behind a failed card's "tap to retry", and the mandatory first
  /// half of the reconnect sequence.
  Future<void> refresh() => _fetch(_tracked.toList());

  Future<void> _fetch(List<String> materials) async {
    if (materials.isEmpty) return;
    final customerId = _customerId;

    if (customerId == null || customerId.isEmpty) {
      // A walk-in has nothing to price against. Settled, not broken — the card
      // says so and offers no retry, because retrying asks the same question.
      emit({
        ...state,
        for (final material in materials)
          material: MobilePrice(
            material: material,
            state: PricingState.unavailable,
            errorKind: PricingErrorKind.customerNotFound,
          ),
      });
      return;
    }

    // Only the cards being fetched show a spinner. The rest of the quotation,
    // and every other price on it, stays exactly as it was.
    emit({
      ...state,
      for (final material in materials) material: MobilePrice.loading(material),
    });

    final result = await _getPrices(CustomerPricesParams(
      customerId: customerId,
      materials: materials,
    ));
    if (isClosed) return;

    result.when(
      success: (prices) {
        final next = {...state};
        for (final price in prices) {
          // A material dropped from the quotation while its request was in
          // flight must not reappear on screen.
          if (!_tracked.contains(price.material)) continue;
          next[price.material] = price;
        }
        emit(next);
      },
      failure: (failure) {
        final next = {...state};
        for (final material in materials) {
          if (!_tracked.contains(material)) continue;
          next[material] = MobilePrice(
            material: material,
            state: PricingState.error,
            errorKind: PricingErrorKind.unknown,
          );
        }
        emit(next);
      },
    );
  }

  /// Applies a pushed price, unless it is older than what is already held.
  void _onRealtimePrice(MobilePrice incoming) {
    if (isClosed) return;
    if (!_tracked.contains(incoming.material)) return;

    final held = state[incoming.material];
    final heldStamp = held?.updatedAt;
    final incomingStamp = incoming.updatedAt;

    // The stale guard. Strictly newer wins; equal stamps are the same
    // publication arriving twice and change nothing.
    if (heldStamp != null &&
        incomingStamp != null &&
        !incomingStamp.isAfter(heldStamp)) {
      return;
    }

    emit({...state, incoming.material: incoming});
  }

  /// The reconnect sequence: REST first, then resume.
  ///
  /// The hub does not replay what was missed while the socket was down, so
  /// whatever is on screen is of unknown age until REST says otherwise.
  Future<void> _onReconnected() async {
    if (isClosed) return;
    final customerId = _customerId;
    if (customerId == null || customerId.isEmpty) return;

    await _realtime.subscribe(customerId);
    if (isClosed) return;
    await refresh();
  }

  /// Marks every held price as no longer known to be current.
  ///
  /// Called when the transport drops. The figures stay on screen — a rep
  /// mid-conversation should not watch prices vanish — but they lose the live
  /// indicator, which is the honest rendering of "this was true a moment ago".
  void markStale() {
    if (state.isEmpty) return;
    emit({
      for (final entry in state.entries)
        entry.key: entry.value.copyWith(
          isStale: true,
          state: entry.value.hasAmount
              ? PricingState.reconnecting
              : entry.value.state,
        ),
    });
  }

  @override
  Future<void> close() {
    _updateSub?.cancel();
    _reconnectSub?.cancel();
    return super.close();
  }
}
