import 'package:location/location.dart';

class LocationService {
  LocationService._();

  static final Location _location = Location();

  static Future<bool> requestPermission() async {
    final permission = await _location.requestPermission();
    return permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited;
  }

  static Future<bool> isEnabled() async {
    return _location.serviceEnabled();
  }

  static Future<bool> requestEnable() async {
    return _location.requestService();
  }

  static Future<LocationData?> getCurrentLocation() async {
    try {
      return _location.getLocation();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> enableBackgroundMode({required bool enable}) async {
    try {
      return await _location.enableBackgroundMode(enable: enable);
    } catch (_) {
      return false;
    }
  }
}
