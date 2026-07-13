import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/halt.dart';
import '../providers/monitor_provider.dart';
import 'frosted_card.dart';

class LiveMapView extends StatefulWidget {
  final String? routeId;

  const LiveMapView({super.key, this.routeId});

  bool get isParentMode => routeId != null;

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  final MapController _mapController = MapController();
  String? _selectedTripId;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final monitor = context.read<MonitorProvider>();
      monitor.loadActiveTrips(routeId: widget.routeId);
      monitor.subscribe(routeId: widget.routeId);
    });
  }

  @override
  void didUpdateWidget(LiveMapView old) {
    super.didUpdateWidget(old);
    if (old.routeId != widget.routeId) {
      final monitor = context.read<MonitorProvider>();
      monitor.loadActiveTrips(routeId: widget.routeId);
      monitor.subscribe(routeId: widget.routeId);
    }
  }

  void _selectTrip(ActiveTrip trip) {
    if (_selectedTripId == trip.locationId) {
      setState(() => _selectedTripId = null);
      return;
    }
    setState(() => _selectedTripId = trip.locationId);
    context.read<MonitorProvider>().loadHalts(trip.routeId, trip.locationId);
    _mapController.move(
      LatLng(trip.latitude, trip.longitude),
      14,
    );
  }

  void _showTripOnMap(ActiveTrip trip) {
    if (_selectedTripId == trip.locationId && _showMap) {
      setState(() => _showMap = false);
    } else {
      _selectTrip(trip);
      setState(() => _showMap = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitorProvider>();
    final trips = monitor.activeTrips;
    ActiveTrip? selected;
    try {
      selected = trips.firstWhere((t) => t.locationId == _selectedTripId);
    } catch (_) {
      if (widget.isParentMode && trips.isNotEmpty) {
        selected = trips.first;
        if (_selectedTripId == null) {
          _selectedTripId = selected.locationId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _selectTrip(selected!);
          });
        }
      }
    }

    return Column(
      children: [
        if (_showMap)
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                FlutterMap(
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
                        for (final t in trips)
                          Marker(
                            point: LatLng(t.latitude, t.longitude),
                            width: selected?.locationId == t.locationId ? 48 : 36,
                            height: selected?.locationId == t.locationId ? 48 : 36,
                            child: GestureDetector(
                              onTap: () => _selectTrip(t),
                              child: Icon(
                                Icons.directions_bus_rounded,
                                color: selected?.locationId == t.locationId
                                    ? const Color(0xFFFFD700)
                                    : Theme.of(context).colorScheme.primary,
                                size: selected?.locationId == t.locationId ? 44 : 32,
                              ),
                            ),
                          ),
                        if (selected != null)
                          for (final halt in monitor.halts)
                            if (halt.latitude != null && halt.longitude != null)
                              Marker(
                                point: LatLng(halt.latitude!, halt.longitude!),
                                width: 40,
                                height: 50,
                                child: _HaltMarker(
                                  stopNumber: halt.stopOrder + 1,
                                  isCompleted:
                                      monitor.completedHaltIds.contains(halt.id),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
                if (selected != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: selected.isStale ? Colors.orange : const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${selected.recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${selected.recordedAt.toLocal().minute.toString().padLeft(2, '0')}:${selected.recordedAt.toLocal().second.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(
                child: trips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bus_alert_outlined,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.isParentMode
                                  ? 'Your bus is not active right now'
                                  : 'No active trips',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          if (widget.isParentMode) ...[
                            if (selected != null)
                              _TripHeaderCard(trip: selected, monitor: monitor),
                            ...monitor.halts.map(
                              (halt) => _HaltTile(
                                halt: halt,
                                isCompleted:
                                    monitor.completedHaltIds.contains(halt.id),
                                onTap: halt.latitude != null &&
                                        halt.longitude != null
                                    ? () => _mapController.move(
                                          LatLng(halt.latitude!, halt.longitude!),
                                          16,
                                        )
                                    : null,
                              ),
                            ),
                          ] else ...[
                            ...trips.map((t) {
                              final isSelected =
                                  selected?.locationId == t.locationId;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: FrostedCard(
                                  child: InkWell(
                                    onTap: () => _selectTrip(t),
                                    borderRadius: BorderRadius.circular(12),
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
                                              child: Icon(
                                                Icons.warning_amber_rounded,
                                                size: 14,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  t.routeName,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  t.driverPhone,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${t.recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${t.recordedAt.toLocal().minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(20),
                                            onTap: () => _showTripOnMap(t),
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.map,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (selected != null && monitor.halts.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Halts — ${selected.routeName}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              ...monitor.halts.map(
                                (halt) => _HaltTile(
                                  halt: halt,
                                  isCompleted:
                                      monitor.completedHaltIds.contains(halt.id),
                                  onTap: halt.latitude != null &&
                                          halt.longitude != null
                                      ? () => _mapController.move(
                                            LatLng(halt.latitude!, halt.longitude!),
                                            16,
                                          )
                                      : null,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripHeaderCard extends StatelessWidget {
  final ActiveTrip trip;
  final MonitorProvider monitor;

  const _TripHeaderCard({required this.trip, required this.monitor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FrostedCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.routeName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: trip.isStale
                          ? Colors.orange
                          : const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trip.isStale ? 'Signal lost' : 'Active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: trip.isStale
                          ? Colors.orange
                          : const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Last seen: ${trip.recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${trip.recordedAt.toLocal().minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (monitor.completedHaltIds.length < monitor.halts.length) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: monitor.halts.isEmpty
                      ? 0
                      : monitor.completedHaltIds.length / monitor.halts.length,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 4),
                Text(
                  '${monitor.completedHaltIds.length} of ${monitor.halts.length} halts completed',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HaltTile extends StatelessWidget {
  final Halt halt;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _HaltTile({
    required this.halt,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        enabled: onTap != null,
        onTap: onTap,
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: isCompleted
              ? const Color(0xFF4CAF50)
              : Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.2),
          child: Text(
            '${halt.stopOrder + 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCompleted ? Colors.white : null,
            ),
          ),
        ),
        title: Text(halt.name, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          'Arrival: ${halt.arrivalTime}${halt.latitude != null ? '  •  ${halt.latitude!.toStringAsFixed(4)}, ${halt.longitude!.toStringAsFixed(4)}' : ''}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20)
            : null,
      ),
    );
  }
}

class _HaltMarker extends StatelessWidget {
  final int stopNumber;
  final bool isCompleted;

  const _HaltMarker({
    required this.stopNumber,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: (isCompleted
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFFD700))
                    .withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCompleted)
                const Icon(Icons.check, size: 12, color: Colors.white),
              if (isCompleted) const SizedBox(width: 2),
              Text(
                isCompleted ? '' : '$stopNumber',
                style: TextStyle(
                  color: isCompleted ? Colors.white : Colors.black87,
                  fontSize: isCompleted ? 0 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Transform.rotate(
          angle: 3.14159 / 4,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFFD700),
            ),
          ),
        ),
      ],
    );
  }
}
