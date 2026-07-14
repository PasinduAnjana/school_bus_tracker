import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;

  LocationData({required this.latitude, required this.longitude});
}

class LocationService {
  LocationService._();

  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool> isEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  static Future<bool> requestEnable() async {
    return true;
  }

  static Future<LocationData?> getCurrentLocation() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LocationData(latitude: p.latitude, longitude: p.longitude);
    } catch (_) {
      return null;
    }
  }

  static Stream<LocationData> onLocationChanged() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).map((p) => LocationData(latitude: p.latitude, longitude: p.longitude));
  }

  static Future<bool> enableBackgroundMode({required bool enable}) async {
    return true;
  }
}
