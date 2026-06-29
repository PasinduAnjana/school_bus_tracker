import 'package:flutter/foundation.dart';
import '../services/supabase_client.dart';

class WhitelistedUser {
  final String id;
  final String phoneNumber;
  final String role;

  WhitelistedUser({
    required this.id,
    required this.phoneNumber,
    required this.role,
  });

  factory WhitelistedUser.fromMap(Map<String, dynamic> map) {
    return WhitelistedUser(
      id: map['id'] as String,
      phoneNumber: map['phone_number'] as String,
      role: map['role'] as String,
    );
  }
}

class StudentWithParent {
  final String id;
  final String name;
  final String? parentId;
  final String? parentPhone;

  StudentWithParent({
    required this.id,
    required this.name,
    this.parentId,
    this.parentPhone,
  });

  factory StudentWithParent.fromMap(Map<String, dynamic> map) {
    return StudentWithParent(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      parentPhone: map['parent_phone'] as String?,
    );
  }
}

class RouteWithDriver {
  final String id;
  final String name;
  final String? driverId;
  final String? driverPhone;

  RouteWithDriver({
    required this.id,
    required this.name,
    this.driverId,
    this.driverPhone,
  });

  factory RouteWithDriver.fromMap(Map<String, dynamic> map) {
    return RouteWithDriver(
      id: map['id'] as String,
      name: map['name'] as String,
      driverId: map['driver_id'] as String?,
      driverPhone: map['driver_phone'] as String?,
    );
  }
}

class PaymentWithStudent {
  final String id;
  final String studentId;
  final String studentName;
  final String month;
  final bool paid;

  PaymentWithStudent({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.month,
    required this.paid,
  });

  factory PaymentWithStudent.fromMap(Map<String, dynamic> map) {
    return PaymentWithStudent(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      month: map['month'] as String,
      paid: map['paid'] as bool,
    );
  }
}

class AdminProvider extends ChangeNotifier {
  List<WhitelistedUser> _users = [];
  List<StudentWithParent> _students = [];
  List<RouteWithDriver> _routes = [];
  List<PaymentWithStudent> _payments = [];
  String _selectedMonth = '';
  bool _isLoading = false;

  List<WhitelistedUser> get users => _users;
  List<StudentWithParent> get students => _students;
  List<RouteWithDriver> get routes => _routes;
  List<PaymentWithStudent> get payments => _payments;
  List<WhitelistedUser> get drivers =>
      _users.where((u) => u.role == 'Driver').toList();
  List<WhitelistedUser> get parents =>
      _users.where((u) => u.role == 'Parent').toList();
  String get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;

  static String currentMonth() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}-${now.year}';
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await SupabaseService.client
          .from('users_whitelist')
          .select('id, phone_number, role')
          .order('created_at', ascending: false);
      _users = (data as List).map((e) => WhitelistedUser.fromMap(e)).toList();
    } catch (e) {
      debugPrint('loadUsers error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addUser(String phone, String role) async {
    try {
      await SupabaseService.client.from('users_whitelist').insert({
        'phone_number': phone,
        'role': role,
      });
      await loadUsers();
      return true;
    } catch (e) {
      debugPrint('addUser error: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await SupabaseService.client
          .from('users_whitelist')
          .delete()
          .eq('id', id);
      await loadUsers();
      return true;
    } catch (e) {
      debugPrint('deleteUser error: $e');
      return false;
    }
  }

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await SupabaseService.client
          .from('students')
          .select('id, name, parent_id, parent:users_whitelist!parent_id(phone_number)')
          .order('name');
      _students = (data as List).map((e) {
        final map = e as Map<String, dynamic>;
        final parent = map['parent'] as Map<String, dynamic>?;
        return StudentWithParent(
          id: map['id'] as String,
          name: map['name'] as String,
          parentId: map['parent_id'] as String?,
          parentPhone: parent?['phone_number'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('loadStudents error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  WhitelistedUser? findUserByPhone(String phone) {
    try {
      return _users.firstWhere((u) => u.phoneNumber == phone);
    } catch (_) {
      return null;
    }
  }

  Future<bool> addStudentWithParent(
      String studentName, String parentPhone, String? parentName) async {
    try {
      var parent = findUserByPhone(parentPhone);
      if (parent == null) {
        final name = parentName?.trim();
        if (name == null || name.isEmpty) return false;
        await SupabaseService.client.from('users_whitelist').insert({
          'phone_number': parentPhone,
          'role': 'Parent',
        });
        await loadUsers();
        parent = findUserByPhone(parentPhone);
        if (parent == null) return false;
      }
      await SupabaseService.client.from('students').insert({
        'name': studentName,
        'parent_id': parent.id,
      });
      await loadStudents();
      return true;
    } catch (e) {
      debugPrint('addStudentWithParent error: $e');
      return false;
    }
  }

  Future<bool> deleteStudent(String id) async {
    try {
      await SupabaseService.client
          .from('students')
          .delete()
          .eq('id', id);
      await loadStudents();
      return true;
    } catch (e) {
      debugPrint('deleteStudent error: $e');
      return false;
    }
  }

  Future<void> loadRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await SupabaseService.client
          .from('routes')
          .select('id, name, driver_id, driver:users_whitelist!driver_id(phone_number)')
          .order('name');
      _routes = (data as List).map((e) {
        final map = e as Map<String, dynamic>;
        final driver = map['driver'] as Map<String, dynamic>?;
        return RouteWithDriver(
          id: map['id'] as String,
          name: map['name'] as String,
          driverId: map['driver_id'] as String?,
          driverPhone: driver?['phone_number'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('loadRoutes error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> assignDriver(String routeId, String? driverId) async {
    try {
      await SupabaseService.client
          .from('routes')
          .update({'driver_id': driverId})
          .eq('id', routeId);
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('assignDriver error: $e');
      return false;
    }
  }

  Future<void> loadPayments(String month) async {
    _selectedMonth = month;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await SupabaseService.client
          .from('payments')
          .select('id, student_id, month, paid, student:students!student_id(name)')
          .eq('month', month)
          .order('student_id');
      _payments = (data as List).map((e) {
        final map = e as Map<String, dynamic>;
        final student = map['student'] as Map<String, dynamic>;
        return PaymentWithStudent(
          id: map['id'] as String,
          studentId: map['student_id'] as String,
          studentName: student['name'] as String,
          month: map['month'] as String,
          paid: map['paid'] as bool,
        );
      }).toList();
    } catch (e) {
      debugPrint('loadPayments error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> togglePayment(String paymentId, bool currentValue) async {
    try {
      await SupabaseService.client
          .from('payments')
          .update({'paid': !currentValue})
          .eq('id', paymentId);
      await loadPayments(_selectedMonth);
      return true;
    } catch (e) {
      debugPrint('togglePayment error: $e');
      return false;
    }
  }
}
