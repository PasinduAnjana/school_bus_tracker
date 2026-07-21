import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/admin_provider.dart';
import '../../services/route_service.dart';
import '../../utils/polyline_utils.dart';
import '../../widgets/map_pin.dart';

class RoutePathScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const RoutePathScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  State<RoutePathScreen> createState() => _RoutePathScreenState();
}

class _RoutePathScreenState extends State<RoutePathScreen> {
  final _mapController = MapController();
  List<LatLng> _allPoints = [];
  List<LatLng> _customWaypoints = [];
  List<LatLng> _polylinePath = [];
  bool _isLoading = true;
  bool _isSaving = false;
  late List<Halt> _halts;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final admin = context.read<AdminProvider>();
    final route = admin.routes.firstWhere((r) => r.id == widget.routeId);
    _halts = admin.halts(widget.routeId)
        .where((h) => h.latitude != null && h.longitude != null)
        .toList();

    _allPoints = _halts.map((h) => LatLng(h.latitude!, h.longitude!)).toList();

    if (route.waypoints != null && route.waypoints!.isNotEmpty) {
      for (final wp in route.waypoints!) {
        final latlng = LatLng(wp['lat'] as double, wp['lng'] as double);
        _customWaypoints.add(latlng);
        _insertWaypointOptimally(latlng);
      }
    }

    if (route.encodedPath != null && route.encodedPath!.isNotEmpty) {
      _polylinePath = PolylineUtils.decode(route.encodedPath!);
    } else {
      await _recalculatePath();
    }

    setState(() {
      _isLoading = false;
    });

    if (_allPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_allPoints.first, 13);
      });
    }
  }

  void _insertWaypointOptimally(LatLng pt) {
    if (_allPoints.length < 2) {
      _allPoints.add(pt);
      return;
    }

    int bestIndex = 1;
    double minDelta = double.infinity;
    final distance = const Distance();

    for (int i = 0; i < _allPoints.length - 1; i++) {
      final p1 = _allPoints[i];
      final p2 = _allPoints[i + 1];

      final d1 = distance.as(LengthUnit.Meter, p1, pt);
      final d2 = distance.as(LengthUnit.Meter, pt, p2);
      final d3 = distance.as(LengthUnit.Meter, p1, p2);

      final delta = d1 + d2 - d3;
      if (delta < minDelta) {
        minDelta = delta;
        bestIndex = i + 1;
      }
    }

    _allPoints.insert(bestIndex, pt);
  }

  Future<void> _recalculatePath() async {
    if (_allPoints.length < 2) return;
    setState(() => _isLoading = true);
    final path = await RouteService.getRoute(_allPoints);
    if (mounted) {
      setState(() {
        _polylinePath = path;
        _isLoading = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    // Check if tapped near an existing waypoint to remove it
    final distance = const Distance();
    for (int i = 0; i < _customWaypoints.length; i++) {
      final wp = _customWaypoints[i];
      if (distance.as(LengthUnit.Meter, wp, latlng) < 50) {
        // Remove it
        setState(() {
          _customWaypoints.removeAt(i);
          _allPoints.remove(wp);
        });
        _recalculatePath();
        return;
      }
    }

    // Add new waypoint
    setState(() {
      _customWaypoints.add(latlng);
      _insertWaypointOptimally(latlng);
    });
    _recalculatePath();
  }

  Future<void> _savePath() async {
    setState(() => _isSaving = true);
    final encoded = PolylineUtils.encode(_polylinePath);
    final waypointsJson = _customWaypoints
        .map((w) => {'lat': w.latitude, 'lng': w.longitude})
        .toList();

    final admin = context.read<AdminProvider>();
    final success = await admin.updateRoutePath(
      widget.routeId,
      encoded,
      waypointsJson,
    );

    setState(() => _isSaving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Path saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Path: ${widget.routeName}'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(6.9271, 79.8612),
              initialZoom: 13,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.school_bus_tracker',
              ),
              PolylineLayer(
                polylines: [
                  if (_polylinePath.isNotEmpty)
                    Polyline(
                      points: _polylinePath,
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 4,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Halts
                  ..._halts.map(
                    (h) => Marker(
                      point: LatLng(h.latitude!, h.longitude!),
                      width: 80,
                      height: 40,
                      child: MapPin(
                        label: h.name,
                        size: 24,
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                  ),
                  // Custom Waypoints
                  ..._customWaypoints.map(
                    (w) => Marker(
                      point: w,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Calculating path...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 32 + MediaQuery.of(context).padding.bottom,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Tap the map to add a waypoint. Tap a red waypoint to remove it.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  onPressed: _isSaving ? null : _savePath,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Path'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
