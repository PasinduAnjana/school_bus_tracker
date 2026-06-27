enum UserRole { admin, driver, parent }

class AppUser {
  final String id;
  final String phoneNumber;
  final UserRole role;

  AppUser({
    required this.id,
    required this.phoneNumber,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      phoneNumber: map['phone_number'] as String,
      role: _parseRole(map['role'] as String),
    );
  }

  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'driver':
        return UserRole.driver;
      case 'parent':
        return UserRole.parent;
      default:
        throw ArgumentError('Unknown role: $role');
    }
  }
}
