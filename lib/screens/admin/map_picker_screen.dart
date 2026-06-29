import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
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
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation ?? const LatLng(6.9271, 79.8612);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  static final _streetTypes = {
    'residential', 'secondary', 'primary', 'tertiary', 'unclassified',
    'road', 'service', 'footway', 'path', 'cycleway', 'track',
    'motorway', 'trunk', 'living_street', 'pedestrian',
  };

  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=10&countrycodes=lk');
      final resp = await http.get(url, headers: {
        'User-Agent': 'school_bus_tracker/1.0',
      });
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        final all = list.cast<Map<String, dynamic>>();
        all.sort((a, b) {
          final aIsStreet = _streetTypes.contains(a['type'] as String?);
          final bIsStreet = _streetTypes.contains(b['type'] as String?);
          if (aIsStreet && !bIsStreet) return 1;
          if (!aIsStreet && bIsStreet) return -1;
          return (b['importance'] as num?)?.compareTo(a['importance'] as num? ?? 0) ?? 0;
        });
        setState(() => _results = all.take(5).toList());
      }
    } catch (e) {
      debugPrint('Nominatim search error: $e');
    }
    setState(() => _searching = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(value));
  }

  void _goToResult(Map<String, dynamic> result) {
    final lat = double.parse(result['lat'] as String);
    final lon = double.parse(result['lon'] as String);
    setState(() {
      _selected = LatLng(lat, lon);
      _results = [];
      _searchCtrl.clear();
    });
    _mapController.move(_selected, 16);
    _searchFocus.unfocus();
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
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 13,
              onTap: (_, latlng) => setState(() {
                _selected = latlng;
                _results = [];
                _searchCtrl.clear();
              }),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
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
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search for a school or place...',
                    prefixIcon: _searching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                              setState(() => _results = []);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                if (_results.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = _results[i];
                        return ListTile(
                          dense: true,
                          leading:
                              const Icon(Icons.place, color: Color(0xFFFFD700)),
                          title: Text(r['display_name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          onTap: () => _goToResult(r),
                        );
                      },
                    ),
                  ),
              ],
            ),
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
