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
    _mapController.move(LatLng(trip.latitude, trip.longitude), 14);
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
    Halt? nextHalt;
    try {
      selected = trips.firstWhere((t) => t.locationId == _selectedTripId);
    } catch (_) {
      if (widget.isParentMode && trips.isNotEmpty) {
        selected = trips.first;
        if (_selectedTripId == null) {
          _selectedTripId = selected.locationId;
          _showMap = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _selectTrip(selected!);
          });
        }
      }
    }
    if (selected != null) {
      nextHalt = monitor.halts.isNotEmpty
          ? monitor.halts
                .where((h) => !monitor.completedHaltIds.contains(h.id))
                .firstOrNull
          : null;
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
                            width: selected?.locationId == t.locationId
                                ? 48
                                : 36,
                            height: selected?.locationId == t.locationId
                                ? 48
                                : 36,
                            child: GestureDetector(
                              onTap: () => _selectTrip(t),
                              child: Icon(
                                Icons.directions_bus_rounded,
                                color: selected?.locationId == t.locationId
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.6),
                                size: selected?.locationId == t.locationId
                                    ? 44
                                    : 32,
                              ),
                            ),
                          ),
                        if (selected != null)
                          for (final halt in monitor.halts)
                            if (halt.latitude != null && halt.longitude != null)
                              Marker(
                                point: LatLng(halt.latitude!, halt.longitude!),
                                width:
                                    monitor.completedHaltIds.contains(halt.id)
                                    ? 24
                                    : halt.id == nextHalt?.id
                                    ? 44
                                    : 32,
                                height:
                                    monitor.completedHaltIds.contains(halt.id)
                                    ? 30
                                    : halt.id == nextHalt?.id
                                    ? 44
                                    : 38,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    if (halt.id == nextHalt?.id)
                                      const Positioned(
                                        left: -20,
                                        top: -20,
                                        child: SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: _NextHaltGlow(),
                                        ),
                                      ),
                                    _HaltMarker(
                                      isCompleted: monitor.completedHaltIds
                                          .contains(halt.id),
                                      isNext: halt.id == nextHalt?.id,
                                    ),
                                  ],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withValues(alpha: 0.54),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: selected.isStale
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${selected.recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${selected.recordedAt.toLocal().minute.toString().padLeft(2, '0')}:${selected.recordedAt.toLocal().second.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 10,
                            ),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.isParentMode
                                  ? 'Your bus is not active right now'
                                  : 'No active trips',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
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
                                isCompleted: monitor.completedHaltIds.contains(
                                  halt.id,
                                ),
                                onTap:
                                    halt.latitude != null &&
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
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.error
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.tertiary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          if (t.isStale)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 4,
                                              ),
                                              child: Icon(
                                                Icons.warning_amber_rounded,
                                                size: 14,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
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
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            onTap: () => _showTripOnMap(t),
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.map,
                                                size: 18,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
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
                            if (selected != null &&
                                monitor.halts.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Halts — ${selected.routeName}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              ...monitor.halts.map(
                                (halt) => _HaltTile(
                                  halt: halt,
                                  isCompleted: monitor.completedHaltIds
                                      .contains(halt.id),
                                  onTap:
                                      halt.latitude != null &&
                                          halt.longitude != null
                                      ? () => _mapController.move(
                                          LatLng(
                                            halt.latitude!,
                                            halt.longitude!,
                                          ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: trip.isStale
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trip.isStale ? 'Signal lost' : 'Active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: trip.isStale
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.tertiary,
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
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
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

  const _HaltTile({required this.halt, required this.isCompleted, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        enabled: onTap != null,
        onTap: onTap,
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: isCompleted
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          child: isCompleted
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.surface,
                )
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
        title: Text(halt.name, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          'Arrival: ${halt.arrivalTime}${halt.latitude != null ? '  •  ${halt.latitude!.toStringAsFixed(4)}, ${halt.longitude!.toStringAsFixed(4)}' : ''}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: isCompleted
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              )
            : null,
      ),
    );
  }
}

class _HaltMarker extends StatelessWidget {
  final bool isCompleted;
  final bool isNext;

  const _HaltMarker({required this.isCompleted, this.isNext = false});

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
        ],
      );
    }
    if (isNext) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
    }
    return Icon(
      Icons.location_on,
      color: Theme.of(context).colorScheme.primary,
      size: 28,
    );
  }
}

class _NextHaltGlow extends StatefulWidget {
  const _NextHaltGlow();

  @override
  State<_NextHaltGlow> createState() => _NextHaltGlowState();
}

class _NextHaltGlowState extends State<_NextHaltGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scale = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fade = Tween<double>(
      begin: 0.4,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _fade.value,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
