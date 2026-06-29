import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/halt.dart';

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(h.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          backgroundColor: Colors.white70,
                          fontSize: 11,
                        )),
                  ),
                  const Icon(Icons.location_on,
                      color: Color(0xFF9E9E9E), size: 32),
                ],
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
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.school_bus_tracker',
          ),
          MarkerLayer(
            markers: [
              ...existingMarkers,
              Marker(
                point: _selected,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on,
                    color: Color(0xFFFF5252), size: 40),
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
