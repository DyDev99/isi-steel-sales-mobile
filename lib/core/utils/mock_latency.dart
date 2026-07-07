/// Simulated backend latency for the mock data layer.
///
/// The app currently runs entirely on mock/local data sources; this is the
/// single place that mimics a real (slow) API so loading, skeleton and
/// streaming states are actually exercised end-to-end.
///
/// One knob: change [value] (or set it to [Duration.zero]) to speed the whole
/// app back up. Applied only to *read* paths (catalog/list/credit lookups),
/// never to local mutations like cart edits, so interactions stay snappy.
class MockLatency {
  MockLatency._();

  /// How long a simulated "network" read takes.
  static const Duration value = Duration(milliseconds: 900);

  /// Await this at the start of a mock read to simulate the round-trip.
  static Future<void> tick() =>
      value == Duration.zero ? Future<void>.value() : Future<void>.delayed(value);
}
