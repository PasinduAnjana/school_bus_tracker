import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/halt.dart';
import '../services/supabase_client.dart';

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

  bool get isStale =>
      DateTime.now().difference(recordedAt).inMinutes > 2;

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

  List<ActiveTrip> get activeTrips => _activeTrips;
  List<Halt> get halts => _halts;
  Set<String> get completedHaltIds => _completedHaltIds;

  Future<void> loadActiveTrips() async {
    try {
      final data = await SupabaseService.client
          .from('live_locations')
          .select('id, route_id, driver_id, latitude, longitude, recorded_at, '
              'route:routes(name), driver:users_whitelist(phone_number)')
          .eq('trip_active', true)
          .order('recorded_at', ascending: false);
      _activeTrips = (data as List)
          .map((e) => ActiveTrip.fromMap(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadActiveTrips error: $e');
    }
  }

  void subscribe() {
    _channel?.unsubscribe();
    _channel = SupabaseService.client
        .channel('monitor-active-trips')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_active',
            value: true,
          ),
          callback: (_) {
            loadActiveTrips();
          },
        )
        .subscribe();
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
          .order('stop_order');
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
