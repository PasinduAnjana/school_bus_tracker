import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

const _serviceNotificationId = 888;

Timer? _pingTimer;

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
  final location = Location();

  service.on('stopService').listen((_) {
    _pingTimer?.cancel();
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
    _pingTimer?.cancel();

    final supabaseUrl = event['supabaseUrl'] as String?;
    final anonKey = event['anonKey'] as String?;
    final jwtToken = event['jwtToken'] as String?;
    final liveLocationId = event['liveLocationId'] as String?;
    final routeName = event['routeName'] as String? ?? 'Unknown';
    final haltsText = event['haltsText'] as String?;

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

    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        final loc = await location.getLocation();
        if (loc.latitude == null || loc.longitude == null) return;

        final recordedAt = DateTime.now().toUtc().toIso8601String();

        final url = Uri.parse(
          '$supabaseUrl/rest/v1/live_locations?id=eq.$liveLocationId',
        );
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
    });
  });

  await Completer<void>().future;
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}
