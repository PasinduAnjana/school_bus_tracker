class Halt {
  final String id;
  final String routeId;
  final String name;
  final String arrivalTime;
  final double? latitude;
  final double? longitude;
  final int stopOrder;

  Halt({
    required this.id,
    required this.routeId,
    required this.name,
    required this.arrivalTime,
    this.latitude,
    this.longitude,
    required this.stopOrder,
  });

  factory Halt.fromMap(Map<String, dynamic> map) {
    final time = map['arrival_time'];
    String arrivalTime;
    if (time is String) {
      arrivalTime = time.substring(0, 5);
    } else {
      final t = time as Map;
      final hour = (t['hour'] as int).toString().padLeft(2, '0');
      final minute = (t['minute'] as int).toString().padLeft(2, '0');
      arrivalTime = '$hour:$minute';
    }

    return Halt(
      id: map['id'] as String,
      routeId: map['route_id'] as String,
      name: map['name'] as String,
      arrivalTime: arrivalTime,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      stopOrder: map['stop_order'] as int? ?? 0,
    );
  }
}
