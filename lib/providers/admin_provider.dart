import 'package:flutter/foundation.dart';
import '../models/halt.dart';
import '../services/supabase_client.dart';
import '../utils/phone_utils.dart';

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
  final Map<String, List<Halt>> _haltsByRoute = {};
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

  List<Halt> halts(String routeId) =>
      _haltsByRoute[routeId] ?? [];

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
        'phone_number': formatE164(phone),
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
    final normalized = formatE164(phone);
    try {
      return _users.firstWhere((u) => u.phoneNumber == normalized);
    } catch (_) {
      return null;
    }
  }

  Future<bool> addStudentWithParent(
      String studentName, String parentPhone, String? parentName) async {
    try {
      final normalizedPhone = formatE164(parentPhone);
      var parent = findUserByPhone(normalizedPhone);
      if (parent == null) {
        final name = parentName?.trim();
        if (name == null || name.isEmpty) return false;
        await SupabaseService.client.from('users_whitelist').insert({
          'phone_number': normalizedPhone,
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

  Future<bool> createRoute(String name) async {
    try {
      await SupabaseService.client.from('routes').insert({'name': name});
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('createRoute error: $e');
      return false;
    }
  }

  Future<bool> deleteRoute(String id) async {
    try {
      await SupabaseService.client.from('routes').delete().eq('id', id);
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('deleteRoute error: $e');
      return false;
    }
  }

  Future<void> loadHalts(String routeId) async {
    try {
      final data = await SupabaseService.client
          .from('halts')
          .select('*')
          .eq('route_id', routeId)
          .order('stop_order');
      _haltsByRoute[routeId] =
          (data as List).map((e) => Halt.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadHalts error: $e');
    }
  }

  Future<bool> addHalt(
      String routeId, String name, String arrivalTime,
      {double? latitude, double? longitude}) async {
    try {
      final halts = _haltsByRoute[routeId] ?? [];
      await SupabaseService.client.from('halts').insert({
        'route_id': routeId,
        'name': name,
        'arrival_time': arrivalTime,
        'latitude': latitude,
        'longitude': longitude,
        'stop_order': halts.length,
      });
      await loadHalts(routeId);
      return true;
    } catch (e) {
      debugPrint('addHalt error: $e');
      return false;
    }
  }

  Future<bool> updateHalt(
      String haltId,
      String name,
      String arrivalTime,
      {double? latitude, double? longitude}) async {
    try {
      await SupabaseService.client.from('halts').update({
        'name': name,
        'arrival_time': arrivalTime,
        'latitude': latitude,
        'longitude': longitude,
      }).eq('id', haltId);
      final routeId = _haltsByRoute.entries
          .firstWhere((e) => e.value.any((h) => h.id == haltId))
          .key;
      await loadHalts(routeId);
      return true;
    } catch (e) {
      debugPrint('updateHalt error: $e');
      return false;
    }
  }

  Future<bool> deleteHalt(String haltId) async {
    try {
      final entry = _haltsByRoute.entries
          .firstWhere((e) => e.value.any((h) => h.id == haltId));
      await SupabaseService.client
          .from('halts')
          .delete()
          .eq('id', haltId);
      await loadHalts(entry.key);
      return true;
    } catch (e) {
      debugPrint('deleteHalt error: $e');
      return false;
    }
  }

  Future<void> reorderHalts(String routeId, List<String> haltIds) async {
    try {
      final existing = _haltsByRoute[routeId];
      if (existing == null) return;
      final reordered = haltIds.map((id) => existing.firstWhere((h) => h.id == id)).toList();
      for (var i = 0; i < reordered.length; i++) {
        reordered[i] = Halt(
          id: reordered[i].id,
          routeId: reordered[i].routeId,
          name: reordered[i].name,
          arrivalTime: reordered[i].arrivalTime,
          latitude: reordered[i].latitude,
          longitude: reordered[i].longitude,
          stopOrder: i,
        );
      }
      _haltsByRoute[routeId] = reordered;
      notifyListeners();

      for (var i = 0; i < haltIds.length; i++) {
        await SupabaseService.client
            .from('halts')
            .update({'stop_order': i})
            .eq('id', haltIds[i]);
      }
    } catch (e) {
      debugPrint('reorderHalts error: $e');
      await loadHalts(routeId);
    }
  }

  Future<void> loadPayments(String month) async {
    _selectedMonth = month;
    _isLoading = true;
    notifyListeners();
    try {
      final payments = await SupabaseService.client
          .from('payments')
          .select('id, student_id, month, paid, student:students!student_id(name)')
          .eq('month', month)
          .order('student_id');
      _payments = (payments as List).map((e) {
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

      final paidStudentIds = _payments.map((p) => p.studentId).toSet();

      final students = await SupabaseService.client
          .from('students')
          .select('id, name');
      for (final s in students as List) {
        final map = s as Map<String, dynamic>;
        if (!paidStudentIds.contains(map['id'] as String)) {
          await SupabaseService.client.from('payments').insert({
            'student_id': map['id'],
            'month': month,
            'paid': false,
          });
        }
      }

      await _reloadPayments(month);
    } catch (e) {
      debugPrint('loadPayments error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadPayments(String month) async {
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
