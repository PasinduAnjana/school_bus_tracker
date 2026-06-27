class GpsLocation {
  final String id;
  final String? routeId;
  final String? driverId;
  final double latitude;
  final double longitude;
  final bool tripActive;
  final DateTime recordedAt;

  GpsLocation({
    required this.id,
    this.routeId,
    this.driverId,
    required this.latitude,
    required this.longitude,
    required this.tripActive,
    required this.recordedAt,
  });

  factory GpsLocation.fromMap(Map<String, dynamic> map) {
    return GpsLocation(
      id: map['id'] as String,
      routeId: map['route_id'] as String?,
      driverId: map['driver_id'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      tripActive: map['trip_active'] as bool,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }
}
