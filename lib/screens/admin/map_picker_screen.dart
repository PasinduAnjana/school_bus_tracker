import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/halt.dart';
import '../../widgets/map_pin.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final List<Halt> existingHalts;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
    this.existingHalts = const [],
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation ?? const LatLng(6.9271, 79.8612);
  }

  @override
  Widget build(BuildContext context) {
    final existingMarkers = widget.existingHalts
        .where((h) => h.latitude != null && h.longitude != null)
        .map((h) => Marker(
              point: LatLng(h.latitude!, h.longitude!),
              width: 120,
              height: 60,
              child: MapPin(
                label: h.name,
                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                size: 32,
              ),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _selected,
          initialZoom: 13,
          onTap: (_, latlng) => setState(() => _selected = latlng),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.school_bus_tracker',
          ),
          MarkerLayer(
            markers: [
              ...existingMarkers,
              Marker(
                point: _selected,
                width: 40,
                height: 60,
                child: const MapPin(size: 40),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, _selected),
        icon: const Icon(Icons.check),
        label: const Text('Confirm'),
      ),
    );
  }
}
