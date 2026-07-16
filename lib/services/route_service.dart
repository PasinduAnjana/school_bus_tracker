import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class RouteService {
  static const String _baseUrl = 'http://router.project-osrm.org/route/v1/driving';

  // Cache to avoid hitting OSRM unnecessarily if the target halt hasn't changed
  // Key format: "startLat,startLng|endLat,endLng" (rounded for cache hits)
  static final Map<String, List<LatLng>> _cache = {};

  /// Fetches a route between multiple points using OSRM.
  static Future<List<LatLng>> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return [];

    // A simple rounding to avoid fetching again if the points are virtually the same
    final cacheKey = waypoints.map((w) => '${w.latitude.toStringAsFixed(4)},${w.longitude.toStringAsFixed(4)}').join('|');
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final coordsString = waypoints.map((w) => '${w.longitude},${w.latitude}').join(';');
      final url = Uri.parse(
          '$_baseUrl/$coordsString?overview=full&geometries=geojson');
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          final path = coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();
          
          _cache[cacheKey] = path;
          // Keep cache small
          if (_cache.length > 20) _cache.remove(_cache.keys.first);
          
          return path;
        }
      }
    } catch (e) {
      debugPrint('RouteService getRoute error: $e');
    }
    return [];
  }
}
