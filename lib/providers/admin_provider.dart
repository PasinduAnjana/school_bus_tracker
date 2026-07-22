import 'package:flutter/foundation.dart';
import '../models/bus.dart';
import '../models/halt.dart';
import '../services/supabase_client.dart';
import '../utils/phone_utils.dart';

class WhitelistedUser {
  final String id;
  final String phoneNumber;
  final String role;
  final String? name;

  WhitelistedUser({
    required this.id,
    required this.phoneNumber,
    required this.role,
    this.name,
  });

  factory WhitelistedUser.fromMap(Map<String, dynamic> map) {
    return WhitelistedUser(
      id: map['id'] as String,
      phoneNumber: map['phone_number'] as String,
      role: map['role'] as String,
      name: map['name'] as String?,
    );
  }
}

class StudentWithParent {
  final String id;
  final String name;
  final String? parentId;
  final String? parentPhone;
  final String? parentName;
  final String? routeId;
  final String? routeName;
  final List<String> busIds;

  StudentWithParent({
    required this.id,
    required this.name,
    this.parentId,
    this.parentPhone,
    this.parentName,
    this.routeId,
    this.routeName,
    this.busIds = const [],
  });

  factory StudentWithParent.fromMap(Map<String, dynamic> map) {
    final route = map['route'] as Map<String, dynamic>?;
    final parent = map['parent'] as Map<String, dynamic>?;
    return StudentWithParent(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      parentPhone: parent?['phone_number'] as String?,
      parentName: parent?['name'] as String?,
      routeId: map['route_id'] as String?,
      routeName: route?['name'] as String?,
      busIds: (map['bus_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class RouteWithDriver {
  final String id;
  final String name;
  final String? driverId;
  final String? driverPhone;
  final String? busId;
  final String? busName;
  final String? encodedPath;
  final List<dynamic>? waypoints;

  RouteWithDriver({
    required this.id,
    required this.name,
    this.driverId,
    this.driverPhone,
    this.busId,
    this.busName,
    this.encodedPath,
    this.waypoints,
  });

  factory RouteWithDriver.fromMap(Map<String, dynamic> map) {
    return RouteWithDriver(
      id: map['id'] as String,
      name: map['name'] as String,
      driverId: map['driver_id'] as String?,
      driverPhone: map['driver_phone'] as String?,
      busId: map['bus_id'] as String?,
      busName: map['bus_name'] as String?,
      encodedPath: map['encoded_path'] as String?,
      waypoints: map['waypoints'] as List<dynamic>?,
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
  List<Bus> _buses = [];
  List<PaymentWithStudent> _payments = [];
  final Map<String, List<Halt>> _haltsByRoute = {};
  String _selectedMonth = '';
  bool _isLoading = false;

  List<WhitelistedUser> get users => _users;
  List<StudentWithParent> get students => _students;
  List<RouteWithDriver> get routes => _routes;
  List<Bus> get buses => _buses;
  List<PaymentWithStudent> get payments => _payments;
  List<WhitelistedUser> get drivers =>
      _users.where((u) => u.role == 'Driver').toList();
  List<WhitelistedUser> get parents =>
      _users.where((u) => u.role == 'Parent').toList();
  String get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;

  List<Halt> halts(String routeId) => _haltsByRoute[routeId] ?? [];

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
          .select('id, phone_number, role, name')
          .order('created_at', ascending: false);
      _users = (data as List).map((e) => WhitelistedUser.fromMap(e)).toList();
    } catch (e) {
      debugPrint('loadUsers error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addUser(String phone, String role, {String? name}) async {
    try {
      await SupabaseService.client.from('users_whitelist').insert({
        'phone_number': formatE164(phone),
        'role': role,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      });
      await loadUsers();
      return true;
    } catch (e) {
      debugPrint('addUser error: $e');
      return false;
    }
  }

  Future<bool> updateUserName(String id, String name) async {
    try {
      await SupabaseService.client
          .from('users_whitelist')
          .update({'name': name.trim()})
          .eq('id', id);
      await loadUsers();
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('Error updating user name: $e');
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
          .select(
            'id, name, parent_id, route_id, bus_ids, parent:users_whitelist!parent_id(phone_number, name), route:routes!route_id(name)',
          )
          .order('name');
      _students = (data as List)
          .map((e) => StudentWithParent.fromMap(e))
          .toList();
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
    String studentName,
    String parentPhone,
    String? parentName, {
    String? routeId,
  }) async {
    try {
      final normalizedPhone = formatE164(parentPhone);
      var parent = findUserByPhone(normalizedPhone);
      if (parent == null) {
        final name = parentName?.trim();
        if (name == null || name.isEmpty) return false;
        await SupabaseService.client.from('users_whitelist').insert({
          'phone_number': normalizedPhone,
          'role': 'Parent',
          'name': name,
        });
        await loadUsers();
        parent = findUserByPhone(parentPhone);
        if (parent == null) return false;
      }
      await SupabaseService.client.from('students').insert({
        'name': studentName,
        'parent_id': parent.id,
        'bus_ids': [],
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
      await SupabaseService.client.from('students').delete().eq('id', id);
      await loadStudents();
      return true;
    } catch (e) {
      debugPrint('deleteStudent error: $e');
      return false;
    }
  }

  Future<bool> updateStudentRoute(String studentId, String? routeId) async {
    try {
      await SupabaseService.client
          .from('students')
          .update({'bus_ids': []}) // Legacy signature - we'll add updateStudentBuses next
          .eq('id', studentId);
      await loadStudents();
      return true;
    } catch (e) {
      debugPrint('updateStudentRoute error: $e');
      return false;
    }
  }

  Future<bool> updateStudentName(String id, String name) async {
    try {
      await SupabaseService.client
          .from('students')
          .update({'name': name.trim()})
          .eq('id', id);
      await loadStudents();
      return true;
    } catch (e) {
      debugPrint('Error updating student name: $e');
      return false;
    }
  }

  Future<void> loadRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await SupabaseService.client
          .from('routes')
          .select(
            'id, name, bus_id, driver_id, encoded_path, waypoints, driver:users_whitelist!driver_id(phone_number, name), bus:buses!bus_id(name)',
          )
          .order('name');
      _routes = (data as List).map((e) {
        final map = e as Map<String, dynamic>;
        final driver = map['driver'] as Map<String, dynamic>?;
        final bus = map['bus'] as Map<String, dynamic>?;
        final driverName = driver?['name'] as String?;
        final driverPhone = driver?['phone_number'] as String?;
        return RouteWithDriver(
          id: map['id'] as String,
          name: map['name'] as String,
          driverId: map['driver_id'] as String?,
          driverPhone: driverName != null ? '$driverName ($driverPhone)' : driverPhone,
          busId: map['bus_id'] as String?,
          busName: bus?['name'] as String?,
          encodedPath: map['encoded_path'] as String?,
          waypoints: map['waypoints'] as List<dynamic>?,
        );
      }).toList();
    } catch (e) {
      debugPrint('loadRoutes error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> assignBusToRoute(String routeId, String? busId) async {
    try {
      await SupabaseService.client
          .from('routes')
          .update({'bus_id': busId})
          .eq('id', routeId);
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('assignBusToRoute error: $e');
      return false;
    }
  }

  Future<bool> createRoute(String name, {String? busId}) async {
    try {
      await SupabaseService.client.from('routes').insert({
        'name': name,
        if (busId != null) 'bus_id': busId,
      });
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('createRoute error: $e');
      return false;
    }
  }

  Future<bool> updateRouteName(String id, String name) async {
    try {
      await SupabaseService.client
          .from('routes')
          .update({'name': name.trim()})
          .eq('id', id);
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('Error updating route name: $e');
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

  Future<bool> updateRoutePath(String id, String encodedPath, List<Map<String, dynamic>> waypoints) async {
    try {
      await SupabaseService.client
          .from('routes')
          .update({
            'encoded_path': encodedPath,
            'waypoints': waypoints,
          })
          .eq('id', id);
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('Error updating route path: $e');
      return false;
    }
  }

  Future<void> loadHalts(String routeId) async {
    try {
      final data = await SupabaseService.client
          .from('halts')
          .select('*')
          .eq('route_id', routeId)
          .order('arrival_time', ascending: true);
      _haltsByRoute[routeId] = (data as List)
          .map((e) => Halt.fromMap(e))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadHalts error: $e');
    }
  }

  Future<bool> addHalt(
    String routeId,
    String name,
    String arrivalTime, {
    double? latitude,
    double? longitude,
  }) async {
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
      await SupabaseService.client
          .from('routes')
          .update({'encoded_path': null, 'waypoints': null})
          .eq('id', routeId);
      await loadHalts(routeId);
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('addHalt error: $e');
      return false;
    }
  }

  Future<bool> updateHalt(
    String haltId,
    String name,
    String arrivalTime, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      await SupabaseService.client
          .from('halts')
          .update({
            'name': name,
            'arrival_time': arrivalTime,
            'latitude': latitude,
            'longitude': longitude,
          })
          .eq('id', haltId);
      final routeId = _haltsByRoute.entries
          .firstWhere((e) => e.value.any((h) => h.id == haltId))
          .key;
      await SupabaseService.client
          .from('routes')
          .update({'encoded_path': null, 'waypoints': null})
          .eq('id', routeId);
      await loadHalts(routeId);
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('updateHalt error: $e');
      return false;
    }
  }

  Future<bool> deleteHalt(String haltId) async {
    try {
      final entry = _haltsByRoute.entries.firstWhere(
        (e) => e.value.any((h) => h.id == haltId),
      );
      await SupabaseService.client.from('halts').delete().eq('id', haltId);
      await SupabaseService.client
          .from('routes')
          .update({'encoded_path': null, 'waypoints': null})
          .eq('id', entry.key);
      await loadHalts(entry.key);
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('deleteHalt error: $e');
      return false;
    }
  }

  Future<void> loadPayments(String month) async {
    _selectedMonth = month;
    _isLoading = true;
    notifyListeners();
    try {
      final payments = await SupabaseService.client
          .from('payments')
          .select(
            'id, student_id, month, paid, student:students!student_id(name)',
          )
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
        .select(
          'id, student_id, month, paid, student:students!student_id(name)',
        )
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
    final newValue = !currentValue;
    final idx = _payments.indexWhere((p) => p.id == paymentId);
    if (idx != -1) {
      _payments[idx] = PaymentWithStudent(
        id: _payments[idx].id,
        studentId: _payments[idx].studentId,
        studentName: _payments[idx].studentName,
        month: _payments[idx].month,
        paid: newValue,
      );
      notifyListeners();
    }

    try {
      await SupabaseService.client
          .from('payments')
          .update({'paid': newValue})
          .eq('id', paymentId);
      return true;
    } catch (e) {
      if (idx != -1) {
        _payments[idx] = PaymentWithStudent(
          id: _payments[idx].id,
          studentId: _payments[idx].studentId,
          studentName: _payments[idx].studentName,
          month: _payments[idx].month,
          paid: currentValue,
        );
        notifyListeners();
      }
      debugPrint('togglePayment error: $e');
      return false;
    }
  }

  Future<void> loadBuses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await SupabaseService.client
          .from('buses')
          .select('id, name, driver_id')
          .order('name');
      _buses = (data as List).map((e) => Bus.fromMap(e)).toList();
    } catch (e) {
      debugPrint('loadBuses error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBus(String name) async {
    try {
      await SupabaseService.client.from('buses').insert({'name': name});
      await loadBuses();
      return true;
    } catch (e) {
      debugPrint('createBus error: $e');
      return false;
    }
  }

  Future<bool> assignDriverToBus(String busId, String? driverId) async {
    try {
      await SupabaseService.client
          .from('buses')
          .update({'driver_id': driverId})
          .eq('id', busId);
      await loadBuses();
      await loadRoutes(); // Routes driver_id might update due to trigger
      return true;
    } catch (e) {
      debugPrint('assignDriverToBus error: $e');
      return false;
    }
  }

  Future<bool> updateBusName(String id, String name) async {
    try {
      await SupabaseService.client
          .from('buses')
          .update({'name': name.trim()})
          .eq('id', id);
      await loadBuses();
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('Error updating bus name: $e');
      return false;
    }
  }

  Future<bool> deleteBus(String id) async {
    try {
      await SupabaseService.client.from('buses').delete().eq('id', id);
      await loadBuses();
      await loadRoutes();
      return true;
    } catch (e) {
      debugPrint('deleteBus error: $e');
      return false;
    }
  }

  Future<bool> updateStudentBuses(String studentId, List<String> busIds) async {
    try {
      await SupabaseService.client
          .from('students')
          .update({'bus_ids': busIds})
          .eq('id', studentId);
      await loadStudents();
      return true;
    } catch (e) {
      debugPrint('updateStudentBuses error: $e');
      return false;
    }
  }
}
