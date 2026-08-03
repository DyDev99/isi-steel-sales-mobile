import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/today_stop.dart';

/// Status filter for the Stop Dashboard list.
enum StopFilter { all, pending, checkedIn, completed, skipped }

sealed class StopDashboardState extends Equatable {
  const StopDashboardState();
  @override
  List<Object?> get props => [];
}

/// First frame — the screen shows skeletons (never a blank white screen).
final class StopDashboardLoading extends StopDashboardState {
  const StopDashboardLoading();
}

final class StopDashboardError extends StopDashboardState {
  const StopDashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

/// The live dashboard. [stops] holds the **selected day's** stops sorted
/// nearest-first; the screen renders [visibleStops] (filter + search applied
/// here so widgets stay dumb). [allRoutes] backs the calendar's per-day
/// stop-count dots across every synced day.
final class StopDashboardLoaded extends StopDashboardState {
  const StopDashboardLoaded({
    required this.stops,
    required this.allRoutes,
    required this.selectedDate,
    required this.filter,
    required this.query,
    required this.position,
    required this.locating,
    required this.locationUnavailable,
  });

  /// Selected day's stops, sorted nearest-first (planned order until a GPS fix).
  final List<TodayStop> stops;

  /// Every synced route (all days) — for the calendar's per-day counts.
  final List<RoutePlan> allRoutes;
  final DateTime selectedDate;
  final StopFilter filter;
  final String query;
  final LocationSample? position;

  /// True until the first GPS fix arrives — drives the "locating…" hint.
  final bool locating;

  /// True when location can't be used (permission denied, GPS off, emulator,
  /// timeout, failure). The list falls back to planned order; distances hidden.
  final bool locationUnavailable;

  /// Total stops scheduled on [day] across all routes — the calendar dot count.
  int stopCountForDay(DateTime day) {
    var count = 0;
    for (final r in allRoutes) {
      if (DateUtils.isSameDay(r.visitDate, day)) count += r.stops.length;
    }
    return count;
  }

  bool _matchesFilter(TodayStop s) => switch (filter) {
        StopFilter.all => true,
        StopFilter.pending => s.stop.status == VisitStatus.pending ||
            s.stop.status == VisitStatus.enRoute ||
            s.stop.status == VisitStatus.arrived,
        StopFilter.checkedIn => s.stop.status == VisitStatus.checkedIn,
        StopFilter.completed => s.stop.status == VisitStatus.checkedOut,
        StopFilter.skipped => s.stop.status == VisitStatus.missed,
      };

  bool _matchesQuery(TodayStop s) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final c = s.stop.customer;
    return c.name.toLowerCase().contains(q) ||
        c.code.toLowerCase().contains(q) ||
        c.address.toLowerCase().contains(q) ||
        s.routeName.toLowerCase().contains(q);
  }

  /// Filter + search applied — what the list actually renders.
  List<TodayStop> get visibleStops =>
      stops.where((s) => _matchesFilter(s) && _matchesQuery(s)).toList();

  StopDashboardLoaded copyWith({
    List<TodayStop>? stops,
    List<RoutePlan>? allRoutes,
    DateTime? selectedDate,
    StopFilter? filter,
    String? query,
    LocationSample? position,
    bool? locating,
    bool? locationUnavailable,
  }) {
    return StopDashboardLoaded(
      stops: stops ?? this.stops,
      allRoutes: allRoutes ?? this.allRoutes,
      selectedDate: selectedDate ?? this.selectedDate,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      position: position ?? this.position,
      locating: locating ?? this.locating,
      locationUnavailable: locationUnavailable ?? this.locationUnavailable,
    );
  }

  @override
  List<Object?> get props => [
        stops,
        allRoutes,
        selectedDate,
        filter,
        query,
        position,
        locating,
        locationUnavailable,
      ];
}
