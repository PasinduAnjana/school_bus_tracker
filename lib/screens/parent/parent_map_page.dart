import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/monitor_provider.dart';
import '../../widgets/frosted_card.dart';

class ParentMapPage extends StatefulWidget {
  final Halt? focusHalt;
  final String? routeId;
  const ParentMapPage({super.key, this.focusHalt, this.routeId});

  @override
  State<ParentMapPage> createState() => _ParentMapPageState();
}

class _ParentMapPageState extends State<ParentMapPage> {
  final MapController _mapController = MapController();
  bool _centeredOnce = false;

  @override
  void didUpdateWidget(ParentMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusHalt != null &&
        widget.focusHalt!.id != oldWidget.focusHalt?.id &&
        widget.focusHalt!.latitude != null &&
        widget.focusHalt!.longitude != null) {
      _mapController.move(
        LatLng(widget.focusHalt!.latitude!, widget.focusHalt!.longitude!),
        16,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitorProvider>();
    final trip = monitor.activeTrips
        .where((t) => t.routeId == widget.routeId)
        .firstOrNull;
    final theme = Theme.of(context);

    if (trip != null && !_centeredOnce) {
      _centeredOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(trip.latitude, trip.longitude), 15);
      });
    }

    final nextHalt = monitor.halts.isNotEmpty
        ? monitor.halts
              .where((h) => !monitor.completedHaltIds.contains(h.id))
              .firstOrNull
        : null;

    if (trip == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 16),
            Text(
              'Bus is not active right now',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(trip.latitude, trip.longitude),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              retinaMode: true,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(trip.latitude, trip.longitude),
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.directions_bus,
                    color: theme.colorScheme.primary,
                    size: 36,
                  ),
                ),
                Marker(
                  key: ValueKey('parent_bus_ripple'),
                  point: LatLng(trip.latitude, trip.longitude),
                  width: 80,
                  height: 80,
                  child: const _PingRipple(),
                ),
                for (final halt in monitor.halts)
                  if (halt.latitude != null && halt.longitude != null)
                    if (monitor.completedHaltIds.contains(halt.id))
                      Marker(
                        point: LatLng(halt.latitude!, halt.longitude!),
                        width: 24,
                        height: 24,
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (halt.id == nextHalt?.id)
                      Marker(
                        point: LatLng(halt.latitude!, halt.longitude!),
                        width: 40,
                        height: 40,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned(
                              left: -20,
                              top: -20,
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: _NextHaltGlow(),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Marker(
                        point: LatLng(halt.latitude!, halt.longitude!),
                        width: 28,
                        height: 36,
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _StatusBadge(isStale: trip.isStale),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${trip.recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${trip.recordedAt.toLocal().minute.toString().padLeft(2, '0')}:${trip.recordedAt.toLocal().second.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface,
                fontSize: 11,
              ),
            ),
          ),
        ),
        if (nextHalt != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FrostedCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 14,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    nextHalt.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    nextHalt.arrivalTime,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isStale;
  const _StatusBadge({required this.isStale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isStale
              ? [colorScheme.error, colorScheme.error.withValues(alpha: 0.8)]
              : [
                  colorScheme.tertiary,
                  colorScheme.tertiary.withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isStale ? colorScheme.error : colorScheme.tertiary)
                .withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isStale ? 'STALE' : 'LIVE',
            style: TextStyle(
              color: colorScheme.surface,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PingRipple extends StatefulWidget {
  const _PingRipple();

  @override
  State<_PingRipple> createState() => _PingRippleState();
}

class _PingRippleState extends State<_PingRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(
      begin: 0.3,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
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
              color: Theme.of(context).colorScheme.tertiary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
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
