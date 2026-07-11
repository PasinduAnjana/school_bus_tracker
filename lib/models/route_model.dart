class BusRoute {
  final String id;
  final String name;
  final String? driverId;

  BusRoute({required this.id, required this.name, this.driverId});

  factory BusRoute.fromMap(Map<String, dynamic> map) {
    return BusRoute(
      id: map['id'] as String,
      name: map['name'] as String,
      driverId: map['driver_id'] as String?,
    );
  }
}
