import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../config/supabase_config.dart';
import '../models/halt.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_client.dart';

class DriverProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _routes = [];
  List<Halt> _halts = [];
  String? _selectedRouteId;
  bool _tripActive = false;
  String? _liveLocationId;
  final Set<String> _completedHalts = {};
  double? _currentLat;
  double? _currentLng;
  DateTime? _lastPing;
  int _pingSignal = 0;
  Timer? _pingTimer;
  StreamSubscription<LocationData>? _locationStream;
  bool _gpsReady = false;
  bool _resumed = false;

  List<Map<String, dynamic>> get routes => _routes;
  List<Halt> get halts => _halts;
  String? get selectedRouteId => _selectedRouteId;
  bool get tripActive => _tripActive;
  Set<String> get completedHalts => _completedHalts;
  double? get currentLat => _currentLat;
  double? get currentLng => _currentLng;
  DateTime? get lastPing => _lastPing;
  int get pingSignal => _pingSignal;
  bool get gpsReady => _gpsReady;
  bool get resumed => _resumed;

  String? get selectedRouteName {
    if (_selectedRouteId == null) return null;
    try {
      return _routes.firstWhere((r) => r['id'] == _selectedRouteId)['name']
          as String;
    } catch (_) {
      return null;
    }
  }

  Future<void> initGps() async {
    final permitted = await LocationService.requestPermission();
    if (!permitted) return;
    final enabled = await LocationService.isEnabled();
    if (!enabled) {
      await LocationService.requestEnable();
    }
    _gpsReady = true;
    _locationStream = LocationService.onLocationChanged().listen((loc) {
      if (loc.latitude != null && loc.longitude != null) {
        _currentLat = loc.latitude;
        _currentLng = loc.longitude;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> loadRoutes(String driverId) async {
    try {
      final data = await SupabaseService.client
          .from('routes')
          .select('id, name')
          .eq('driver_id', driverId)
          .order('name');
      _routes = (data as List).cast<Map<String, dynamic>>();
      if (_routes.length == 1) {
        _selectedRouteId = _routes[0]['id'] as String;
        await _loadHalts(_selectedRouteId!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('DriverProvider loadRoutes error: $e');
    }
  }

  Future<void> resumeActiveTrip(String driverId) async {
    try {
      final row = await SupabaseService.client
          .from('live_locations')
          .select('id, route_id, latitude, longitude, recorded_at')
          .eq('driver_id', driverId)
          .eq('trip_active', true)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return;

      final lastPingTime = DateTime.parse(row['recorded_at'] as String);
      final stale = DateTime.now().difference(lastPingTime).inMinutes > 5;

      if (stale) {
        await SupabaseService.client
            .from('live_locations')
            .update({'trip_active': false})
            .eq('id', row['id'] as String);
        return;
      }

      _liveLocationId = row['id'] as String;
      _selectedRouteId = row['route_id'] as String;
      _currentLat = (row['latitude'] as num?)?.toDouble();
      _currentLng = (row['longitude'] as num?)?.toDouble();
      _lastPing = lastPingTime;
      _tripActive = true;
      _resumed = true;

      if (_routes.where((r) => r['id'] == _selectedRouteId).isEmpty) {
        _routes = [
          {'id': _selectedRouteId, 'name': 'Unknown'},
        ];
      }

      await _loadHalts(_selectedRouteId!);
      notifyListeners();
      _startPinging(driverId);
      unawaited(_startBackgroundService(driverId));
    } catch (e) {
      debugPrint('resumeActiveTrip error: $e');
    }
  }

  Future<void> selectRoute(String routeId) async {
    _selectedRouteId = routeId;
    _completedHalts.clear();
    notifyListeners();
    await _loadHalts(routeId);
  }

  Future<void> _loadHalts(String routeId) async {
    try {
      final data = await SupabaseService.client
          .from('halts')
          .select('*')
          .eq('route_id', routeId)
          .order('arrival_time', ascending: true);
      _halts = (data as List).map((e) => Halt.fromMap(e)).toList();

      if (_liveLocationId != null) {
        final tripData = await SupabaseService.client
            .from('trip_halts')
            .select('halt_id')
            .eq('live_location_id', _liveLocationId!);
        _completedHalts.clear();
        for (final row in tripData as List) {
          _completedHalts.add(row['halt_id'] as String);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('DriverProvider loadHalts error: $e');
    }
  }

  Future<void> startTrip(String driverId) async {
    final loc = await LocationService.getCurrentLocation();
    if (loc == null || loc.latitude == null || loc.longitude == null) return;

    _currentLat = loc.latitude;
    _currentLng = loc.longitude;
    _tripActive = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('live_locations')
          .insert({
            'route_id': _selectedRouteId!,
            'driver_id': driverId,
            'latitude': _currentLat,
            'longitude': _currentLng,
            'trip_active': true,
          })
          .select('id')
          .single();
      _liveLocationId = response['id'] as String;

      await _loadHalts(_selectedRouteId!);

      _tripActive = true;
      notifyListeners();
      _startPinging(driverId);

      unawaited(_startBackgroundService(driverId));
    } catch (e) {
      debugPrint('startTrip error: $e');
    }
  }

  Future<void> _startBackgroundService(String driverId) async {
    final service = FlutterBackgroundService();
    final session = SupabaseService.client.auth.currentSession;
    final jwt = session?.accessToken;
    if (jwt == null) return;

    if (!(await service.isRunning())) {
      await service.startService();
      // Wait for the background isolate to initialize and set up its listeners
      await Future.delayed(const Duration(seconds: 2));
    }

    final routeName = selectedRouteName ?? 'Unknown';
    final haltsText = _halts.isNotEmpty
        ? '${_completedHalts.length}/${_halts.length} halts'
        : null;

    service.invoke('startTrip', {
      'supabaseUrl': SupabaseConfig.supabaseUrl,
      'anonKey': SupabaseConfig.anonKey,
      'jwtToken': jwt,
      'liveLocationId': _liveLocationId,
      'routeName': routeName,
      'haltsText': haltsText,
    });
  }

  void _sendNotificationUpdate() {
    final routeName = selectedRouteName ?? 'Unknown';
    final haltsCompleted = _halts.isNotEmpty
        ? '${_completedHalts.length}/${_halts.length} halts'
        : null;
    FlutterBackgroundService().invoke('updateNotification', {
      'title': 'Trip: $routeName',
      'content': haltsCompleted ?? 'Tracking active',
    });
  }

  Future<void> stopTrip() async {
    _tripActive = false;
    _completedHalts.clear();
    notifyListeners();
    _stopPinging();

    final loc = await LocationService.getCurrentLocation();
    if (loc != null) {
      _currentLat = loc.latitude;
      _currentLng = loc.longitude;
    }

    try {
      await SupabaseService.client
          .from('live_locations')
          .update({
            'latitude': _currentLat,
            'longitude': _currentLng,
            'trip_active': false,
          })
          .eq('id', _liveLocationId!);
    } catch (e) {
      debugPrint('stopTrip error: $e');
    }

    FlutterBackgroundService().invoke('stopService');
    NotificationService.cancelTripStatus();

    _locationStream?.cancel();
    _locationStream = null;
    _tripActive = false;
    _liveLocationId = null;
    _completedHalts.clear();
    _lastPing = null;
    _resumed = false;
    notifyListeners();
  }

  void _startPinging(String driverId) {
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _pingLocation(driverId);
    });
  }

  void _stopPinging() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _locationStream?.cancel();
    _locationStream = null;
  }

  Future<void> _pingLocation(String driverId) async {
    final loc = await LocationService.getCurrentLocation();
    if (loc == null || loc.latitude == null || loc.longitude == null) return;

    _currentLat = loc.latitude;
    _currentLng = loc.longitude;
    _lastPing = DateTime.now();
    notifyListeners();

    try {
      await SupabaseService.client
          .from('live_locations')
          .update({
            'latitude': _currentLat,
            'longitude': _currentLng,
            'recorded_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _liveLocationId!);
      _pingSignal++;
      notifyListeners();
    } catch (e) {
      debugPrint('pingLocation error: $e');
    }

    await _checkHaltProximity();
    _sendNotificationUpdate();
  }

  Future<void> _checkHaltProximity() async {
    if (_currentLat == null || _currentLng == null) return;
    if (_liveLocationId == null) return;

    for (final halt in _halts) {
      if (_completedHalts.contains(halt.id)) continue;
      if (halt.latitude == null || halt.longitude == null) continue;

      final dist = _haversine(
        _currentLat!,
        _currentLng!,
        halt.latitude!,
        halt.longitude!,
      );

      if (dist <= 5) {
        _completedHalts.add(halt.id);
        try {
          await SupabaseService.client.from('trip_halts').insert({
            'live_location_id': _liveLocationId!,
            'halt_id': halt.id,
          });
        } catch (e) {
          debugPrint('auto-complete halt error: $e');
        }
      }
    }
    if (_completedHalts.isNotEmpty) notifyListeners();
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        _sin2(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            _sin2(dLon / 2);
    return r * 2 * math.asin(math.sqrt(a));
  }

  double _toRadians(double deg) => deg * math.pi / 180.0;
  double _sin2(double x) => math.sin(x) * math.sin(x);

  void reset() {
    _stopPinging();
    _selectedRouteId = null;
    _halts = [];
    _tripActive = false;
    _liveLocationId = null;
    _completedHalts.clear();
    _currentLat = null;
    _currentLng = null;
    _lastPing = null;
    _gpsReady = false;
    _resumed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPinging();
    super.dispose();
  }
}
