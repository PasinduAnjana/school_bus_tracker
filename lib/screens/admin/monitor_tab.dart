import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/monitor_provider.dart';
import '../../widgets/frosted_card.dart';

class MonitorTab extends StatefulWidget {
  const MonitorTab({super.key});

  @override
  State<MonitorTab> createState() => _MonitorTabState();
}

class _MonitorTabState extends State<MonitorTab> {
  final MapController _mapController = MapController();
  String? _selectedTripId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final monitor = context.read<MonitorProvider>();
      monitor.loadActiveTrips();
      monitor.subscribe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitorProvider>();
    final trips = monitor.activeTrips;
    ActiveTrip? selected;
    try {
      selected = trips.firstWhere((t) => t.locationId == _selectedTripId);
    } catch (_) {
      selected = null;
    }

    return Column(
      children: [
        // Map
        Expanded(
          flex: 2,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(6.9271, 79.8612),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                retinaMode: true,
              ),
              MarkerLayer(
                markers: [
                  // Trip bus markers
                  for (final t in trips)
                    Marker(
                      point: LatLng(t.latitude, t.longitude),
                      width: selected?.locationId == t.locationId ? 48 : 36,
                      height: selected?.locationId == t.locationId ? 48 : 36,
                      child: GestureDetector(
                        onTap: () {
                          setState(() =>
                              _selectedTripId = t.locationId);
                          monitor.loadHalts(t.routeId, t.locationId);
                          _mapController.move(
                            LatLng(t.latitude, t.longitude),
                            14,
                          );
                        },
                        child: Icon(
                          Icons.directions_bus,
                          color: selected?.locationId == t.locationId
                              ? const Color(0xFFFFD700)
                              : Theme.of(context).colorScheme.primary,
                          size: selected?.locationId == t.locationId
                              ? 44
                              : 32,
                        ),
                      ),
                    ),
                  // Halt markers for selected trip
                  if (selected != null)
                    for (final halt in monitor.halts)
                      if (halt.latitude != null && halt.longitude != null)
                        Marker(
                          point: LatLng(halt.latitude!, halt.longitude!),
                          width: 36,
                          height: 44,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: monitor
                                          .completedHaltIds
                                          .contains(halt.id)
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${halt.stopOrder + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                monitor.completedHaltIds.contains(halt.id)
                                    ? Icons.check_circle
                                    : Icons.location_on,
                                color: monitor.completedHaltIds.contains(halt.id)
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFF5252),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
        // Bottom panel
        Expanded(
          flex: 1,
          child: trips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bus_alert,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No active trips',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    // Trip cards
                    ...trips.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: FrostedCard(
                          child: InkWell(
                            onTap: () {
                              setState(() =>
                                  _selectedTripId = t.locationId);
                              monitor.loadHalts(t.routeId, t.locationId);
                              _mapController.move(
                                LatLng(t.latitude, t.longitude),
                                14,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: t.isStale
                                            ? Colors.orange
                                            : const Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    if (t.isStale)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.warning_amber_rounded,
                                            size: 14, color: Colors.orange),
                                      ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(t.routeName,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600)),
                                        Text(t.driverPhone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            )),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${t.recordedAt.hour.toString().padLeft(2, '0')}:${t.recordedAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Halt list for selected trip
                    if (selected != null && monitor.halts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Halts — ${selected.routeName}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      ...monitor.halts.map((halt) => Card(
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 12,
                                backgroundColor: monitor
                                        .completedHaltIds
                                        .contains(halt.id)
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFFD700)
                                        .withValues(alpha: 0.3),
                                child: Text(
                                  '${halt.stopOrder + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: monitor.completedHaltIds
                                            .contains(halt.id)
                                        ? Colors.white
                                        : null,
                                  ),
                                ),
                              ),
                              title: Text(halt.name,
                                  style: const TextStyle(fontSize: 13)),
                              subtitle: Text(
                                'Arrival: ${halt.arrivalTime}${halt.latitude != null ? '  •  ${halt.latitude!.toStringAsFixed(4)}, ${halt.longitude!.toStringAsFixed(4)}' : ''}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: monitor.completedHaltIds
                                      .contains(halt.id)
                                  ? const Icon(Icons.check_circle,
                                      color: Color(0xFF4CAF50), size: 20)
                                  : null,
                            ),
                          )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
