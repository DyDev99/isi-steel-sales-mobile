/// UI-only status for a completed/attempted visit shown in the visit history
/// flow. Deliberately separate from the real `VisitStatus` domain enum used
/// by the live dispatch flow — this model only ever comes from static mock
/// data, never from a repository.
enum VisitHistoryStatus { completed, missed, pending }

/// Plain, UI-only record for one row in the "My Visits" history list. Backed
/// entirely by static mock data — no repository, database, or network call
/// produces this type.
class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.customerName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.visitDate,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.orderPlaced = false,
    this.collectedAmount,
    this.notes,
    this.photoCount = 0,
    this.phoneNumber,
  });

  final String id;
  final String customerName;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime visitDate;
  final VisitHistoryStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool orderPlaced;
  final double? collectedAmount;
  final String? notes;
  final int photoCount;
  final String? phoneNumber;

  Duration? get duration {
    if (checkInTime == null || checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime!);
  }
}
