import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/today_stop.dart';

/// Status filter for the Stop Dashboard list.
enum StopFilter { all, pending, checkedIn, completed, skipped }

/// Aggregate figures for the dashboard summary strip. Pure derived data.
class StopDashboardSummary extends Equatable {
  const StopDashboardSummary({
    required this.total,
    required this.completed,
    required this.remaining,
    required this.nearestName,
    required this.nearestDistanceMeters,
    required this.totalDistanceKm,
    required this.totalTravelMinutes,
  });

  final int total;
  final int completed;
  final int remaining;
  final String? nearestName;
  final double? nearestDistanceMeters;
  final double totalDistanceKm;
  final int totalTravelMinutes;

  static const empty = StopDashboardSummary(
    total: 0,
    completed: 0,
    remaining: 0,
    nearestName: null,
    nearestDistanceMeters: null,
    totalDistanceKm: 0,
    totalTravelMinutes: 0,
  );

  @override
  List<Object?> get props => [
        total,
        completed,
        remaining,
        nearestName,
        nearestDistanceMeters,
        totalDistanceKm,
        totalTravelMinutes,
      ];
}

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

/// The live dashboard: [stops] is the full set sorted nearest-first; the screen
/// renders [visibleStops] (filter + search applied here so widgets stay dumb).
final class StopDashboardLoaded extends StopDashboardState {
  const StopDashboardLoaded({
    required this.stops,
    required this.summary,
    required this.filter,
    required this.query,
    required this.position,
    required this.locating,
    required this.locationDenied,
  });

  /// All today's stops, sorted nearest-first (route/sequence order until a GPS
  /// fix lands).
  final List<TodayStop> stops;
  final StopDashboardSummary summary;
  final StopFilter filter;
  final String query;
  final LocationSample? position;

  /// True until the first GPS fix arrives — drives the "locating…" hint.
  final bool locating;
  final bool locationDenied;

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
    StopDashboardSummary? summary,
    StopFilter? filter,
    String? query,
    LocationSample? position,
    bool? locating,
    bool? locationDenied,
  }) {
    return StopDashboardLoaded(
      stops: stops ?? this.stops,
      summary: summary ?? this.summary,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      position: position ?? this.position,
      locating: locating ?? this.locating,
      locationDenied: locationDenied ?? this.locationDenied,
    );
  }

  @override
  List<Object?> get props =>
      [stops, summary, filter, query, position, locating, locationDenied];
}
