import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/halt.dart';
import '../services/supabase_client.dart';
import 'admin_provider.dart';

class ActiveTrip {
  final String locationId;
  final String routeId;
  final String routeName;
  final String driverId;
  final String driverPhone;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  ActiveTrip({
    required this.locationId,
    required this.routeId,
    required this.routeName,
    required this.driverId,
    required this.driverPhone,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  bool get isStale => DateTime.now().difference(recordedAt).inMinutes > 2;

  factory ActiveTrip.fromMap(Map<String, dynamic> map) {
    final route = map['route'] as Map<String, dynamic>?;
    final driver = map['driver'] as Map<String, dynamic>?;
    return ActiveTrip(
      locationId: map['id'] as String,
      routeId: map['route_id'] as String,
      routeName: route?['name'] as String? ?? 'Unknown',
      driverId: map['driver_id'] as String,
      driverPhone: driver?['phone_number'] as String? ?? 'Unknown',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }
}

class MonitorProvider extends ChangeNotifier {
  List<ActiveTrip> _activeTrips = [];
  List<Halt> _halts = [];
  final Set<String> _completedHaltIds = {};
  RealtimeChannel? _channel;
  List<StudentWithParent> _parentStudents = [];



  List<ActiveTrip> get activeTrips => _activeTrips;
  List<Halt> get halts => _halts;
  Set<String> get completedHaltIds => _completedHaltIds;
  List<StudentWithParent> get parentStudents => _parentStudents;

  // Find the route IDs assigned to this parent's children
  Future<void> loadParentStudents(String parentId) async {
    try {
      final data = await SupabaseService.client
          .from('students')
          .select(
            'id, name, parent_id, route_id, route:routes!route_id(name)',
          )
          .eq('parent_id', parentId);
      _parentStudents = (data as List)
          .map((e) => StudentWithParent.fromMap(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadParentStudents error: $e');
    }
  }

  Future<void> loadActiveTrips({String? routeId}) async {
    try {
      var query = SupabaseService.client
          .from('live_locations')
          .select(
            'id, route_id, driver_id, latitude, longitude, recorded_at, '
            'route:routes(name), driver:users_whitelist(phone_number)',
          )
          .eq('trip_active', true);
      if (routeId != null) {
        query = query.eq('route_id', routeId);
      }
      final data = await query.order('recorded_at', ascending: false);
      _activeTrips = (data as List)
          .map((e) => ActiveTrip.fromMap(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadActiveTrips error: $e');
    }
  }

  void subscribe({String? routeId}) {
    _channel?.unsubscribe();
    final channel = SupabaseService.client
        .channel('monitor-active-trips-${routeId ?? 'all'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_locations',
          callback: (_) {
            loadActiveTrips(routeId: routeId);
          },
        );
    if (routeId != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'trip_halts',
        callback: (_) {
          final trip = _activeTrips.where((t) => t.routeId == routeId);
          for (final t in trip) {
            loadHalts(t.routeId, t.locationId);
          }
        },
      );
    }
    _channel = channel.subscribe();
  }

  void cancel() {
    _channel?.unsubscribe();
    _channel = null;
  }

  Future<void> loadHalts(String routeId, String liveLocationId) async {
    try {
      final haltData = await SupabaseService.client
          .from('halts')
          .select('*')
          .eq('route_id', routeId)
          .order('arrival_time', ascending: true);
      _halts = (haltData as List).map((e) => Halt.fromMap(e)).toList();

      final tripData = await SupabaseService.client
          .from('trip_halts')
          .select('halt_id')
          .eq('live_location_id', liveLocationId);
      _completedHaltIds.clear();
      for (final row in tripData as List) {
        _completedHaltIds.add(row['halt_id'] as String);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('loadHalts error: $e');
    }
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}
