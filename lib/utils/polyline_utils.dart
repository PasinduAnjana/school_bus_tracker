import 'package:latlong2/latlong.dart';

class PolylineUtils {
  static String encode(List<LatLng> points) {
    int lastLat = 0;
    int lastLng = 0;
    StringBuffer result = StringBuffer();

    for (LatLng point in points) {
      int lat = (point.latitude * 1e5).round();
      int lng = (point.longitude * 1e5).round();

      _encodeDiff(lat - lastLat, result);
      _encodeDiff(lng - lastLng, result);

      lastLat = lat;
      lastLng = lng;
    }
    return result.toString();
  }

  static void _encodeDiff(int diff, StringBuffer result) {
    int shifted = diff << 1;
    if (diff < 0) shifted = ~shifted;

    int rem = shifted;
    while (rem >= 0x20) {
      result.write(String.fromCharCode((0x20 | (rem & 0x1f)) + 63));
      rem >>= 5;
    }
    result.write(String.fromCharCode(rem + 63));
  }

  static List<LatLng> decode(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
