import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'dart:math' as math;

double _toRadians(double deg) => deg * math.pi / 180.0;
double _sin2(double x) => math.sin(x) * math.sin(x);

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = _sin2(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          _sin2(dLon / 2);
  return r * 2 * math.asin(math.sqrt(a));
}

const _serviceNotificationId = 888;

StreamSubscription<Position>? _positionStream;

@pragma('vm:entry-point')
void backgroundServiceEntrypoint() {
  FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: false,
      isForegroundMode: true,
      initialNotificationTitle: 'NID Express',
      initialNotificationContent: 'Trip tracking active',
      foregroundServiceNotificationId: _serviceNotificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
      notificationChannelId: 'bus_tracker_foreground',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onStart,
      onBackground: _onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  service.on('stopService').listen((_) {
    _positionStream?.cancel();
    service.stopSelf();
  });

  service.on('updateNotification').listen((event) {
    if (service is AndroidServiceInstance && event is Map<String, dynamic>) {
      service.setForegroundNotificationInfo(
        title: event['title'] as String? ?? 'NID Express',
        content: event['content'] as String? ?? '',
      );
    }
  });

  service.on('startTrip').listen((event) async {
    if (event is! Map<String, dynamic>) return;
    _positionStream?.cancel();

    final supabaseUrl = event['supabaseUrl'] as String?;
    final anonKey = event['anonKey'] as String?;
    final jwtToken = event['jwtToken'] as String?;
    final liveLocationId = event['liveLocationId'] as String?;
    final routeName = event['routeName'] as String? ?? 'Unknown';
    final haltsText = event['haltsText'] as String?;
    
    final halts = event['halts'] as List<dynamic>? ?? [];
    final completedHalts = Set<String>.from(event['completedHalts'] as List<dynamic>? ?? []);

    if (supabaseUrl == null ||
        anonKey == null ||
        jwtToken == null ||
        liveLocationId == null) {
      return;
    }

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Trip: $routeName',
        content: haltsText ?? 'Tracking active',
      );
    }

    DateTime? lastPing;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((loc) async {
      final now = DateTime.now();

      // Proximity Check
      for (final h in halts) {
        final haltId = h['id'] as String?;
        if (haltId == null || completedHalts.contains(haltId)) continue;
        final hLat = (h['latitude'] as num?)?.toDouble();
        final hLng = (h['longitude'] as num?)?.toDouble();
        if (hLat == null || hLng == null) continue;

        final dist = _haversine(loc.latitude, loc.longitude, hLat, hLng);
        if (dist <= 100) {
          completedHalts.add(haltId);
          try {
            await http.post(
              Uri.parse('$supabaseUrl/rest/v1/trip_halts'),
              headers: {
                'apikey': anonKey,
                'Authorization': 'Bearer $jwtToken',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal',
              },
              body: jsonEncode({
                'live_location_id': liveLocationId,
                'halt_id': haltId,
              }),
            );
          } catch (_) {}

          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Trip: $routeName',
              content: '${completedHalts.length}/${halts.length} halts',
            );
          }
        }
      }

      // Ping live location every 20 seconds
      if (lastPing == null || now.difference(lastPing!).inSeconds >= 20) {
        lastPing = now;
        try {
          final recordedAt = now.toUtc().toIso8601String();
          final url = Uri.parse('$supabaseUrl/rest/v1/live_locations?id=eq.$liveLocationId');
          await http.patch(
            url,
            headers: {
              'apikey': anonKey,
              'Authorization': 'Bearer $jwtToken',
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal',
            },
            body: jsonEncode({
              'latitude': loc.latitude,
              'longitude': loc.longitude,
              'recorded_at': recordedAt,
            }),
          );
        } catch (_) {}
      }
    });
  });

  await Completer<void>().future;
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}
