class Student {
  final String id;
  final String name;
  final String? parentId;
  final String? routeId;

  Student({required this.id, required this.name, this.parentId, this.routeId});

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      routeId: map['route_id'] as String?,
    );
  }
}
