class Bus {
  final String id;
  final String name;
  final String? driverId;

  Bus({required this.id, required this.name, this.driverId});

  factory Bus.fromMap(Map<String, dynamic> map) {
    return Bus(
      id: map['id'] as String,
      name: map['name'] as String,
      driverId: map['driver_id'] as String?,
    );
  }
}
