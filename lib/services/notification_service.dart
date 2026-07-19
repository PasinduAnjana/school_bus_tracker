import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _tripStatusChannelId = 'trip_status_high';
  static const _tripStatusChannelName = 'Trip Status';
  static const _tripStatusNotificationId = 1;
  static const foregroundChannelId = 'bus_tracker_foreground_high';
  static const _foregroundChannelName = 'Foreground Service';

  static Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );
    await _plugin.initialize(settings: settings);

    if (!kIsWeb) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _tripStatusChannelId,
            _tripStatusChannelName,
            description: 'Shows the current trip route and status',
            importance: Importance.high,
          ),
        );
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            foregroundChannelId,
            _foregroundChannelName,
            description: 'Required for foreground service to keep trip alive',
            importance: Importance.high,
          ),
        );
      }
    }
  }

  static Future<void> requestPermissions() async {
    if (!kIsWeb) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        await android.requestNotificationsPermission();
      }
    }
  }

  static Future<void> showTripStatus({
    required String routeName,
    required bool isActive,
    String? haltsCompleted,
  }) async {
    final title = isActive ? 'Trip Active' : 'Trip Ended';
    final body = isActive
        ? 'Route: $routeName${haltsCompleted != null ? ' · $haltsCompleted' : ''}'
        : 'Route: $routeName';

    try {
      await _plugin.show(
        id: _tripStatusNotificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _tripStatusChannelId,
            _tripStatusChannelName,
            ongoing: isActive,
            autoCancel: !isActive,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: isActive,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('showTripStatus error: $e');
    }
  }

  static Future<void> cancelTripStatus() async {
    await _plugin.cancel(id: _tripStatusNotificationId);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
