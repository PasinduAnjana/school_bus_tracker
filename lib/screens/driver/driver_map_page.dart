import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/driver_provider.dart';
import '../../services/route_service.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/map_pin.dart';
import '../../widgets/slide_to_end.dart';

class DriverMapPage extends StatefulWidget {
  final Halt? focusHalt;
  const DriverMapPage({super.key, this.focusHalt});

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  final MapController _mapController = MapController();
  bool _centeredOnce = false;

  String? _lastTripLoc;
  String? _lastHaltLoc;
  List<LatLng> _nextHaltPath = [];
  List<LatLng> _remainingPath = [];

  void _checkAndFetchRoute(double tripLat, double tripLng, List<Halt> nextHalts) async {
    if (nextHalts.isEmpty) {
      if (_nextHaltPath.isNotEmpty && mounted) {
        setState(() {
          _nextHaltPath = [];
          _remainingPath = [];
        });
      }
      return;
    }

    final tLoc = '${tripLat.toStringAsFixed(3)},${tripLng.toStringAsFixed(3)}';
    final hLoc = nextHalts.map((h) => '${h.latitude},${h.longitude}').join('|');

    if (_lastTripLoc != tLoc || _lastHaltLoc != hLoc) {
      _lastTripLoc = tLoc;
      _lastHaltLoc = hLoc;
      
      final validHalts = nextHalts
          .where((h) => h.latitude != null && h.longitude != null)
          .map((h) => LatLng(h.latitude!, h.longitude!))
          .toList();

      if (validHalts.isEmpty) return;

      final path1 = await RouteService.getRoute([LatLng(tripLat, tripLng), validHalts.first]);
      
      List<LatLng> path2 = [];
      if (validHalts.length > 1) {
        path2 = await RouteService.getRoute(validHalts);
      }

      if (mounted) {
        setState(() {
          _nextHaltPath = path1;
          _remainingPath = path2;
        });
      }
    }
  }

  @override
  void didUpdateWidget(DriverMapPage oldWidget) {
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
    final driver = context.watch<DriverProvider>();
    final theme = Theme.of(context);

    if (driver.currentLat != null && !_centeredOnce) {
      _centeredOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(driver.currentLat!, driver.currentLng!), 16);
      });
    }

    final maxCompletedIndex = driver.halts
        .lastIndexWhere((h) => driver.completedHalts.contains(h.id));
    final uncompletedHalts = maxCompletedIndex + 1 < driver.halts.length
        ? driver.halts.sublist(maxCompletedIndex + 1)
        : <Halt>[];
    final nextHalt = uncompletedHalts.firstOrNull;

    if (driver.currentLat != null && driver.currentLng != null) {
      _checkAndFetchRoute(driver.currentLat!, driver.currentLng!, uncompletedHalts);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              driver.currentLat ?? 6.9271,
              driver.currentLng ?? 79.8612,
            ),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              retinaMode: true,
            ),
            if (_remainingPath.isNotEmpty || _nextHaltPath.isNotEmpty)
              PolylineLayer(
                polylines: [
                  if (_remainingPath.isNotEmpty)
                    Polyline(
                      points: _remainingPath,
                      strokeWidth: 4,
                      color: Colors.black,
                    ),
                  if (_nextHaltPath.isNotEmpty)
                    Polyline(
                      points: _nextHaltPath,
                      strokeWidth: 5,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            if (driver.currentLat != null && driver.currentLng != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(driver.currentLat!, driver.currentLng!),
                    width: 40,
                    height: 40,
                    child: MapPin(
                      size: 48,
                      label: driver.selectedRouteName ?? 'Bus',
                      color: theme.colorScheme.primary,
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withValues(alpha: 0.5),
                        )
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.05, 1.05),
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.05, 1.05),
                          end: const Offset(0.95, 0.95),
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        ),
                  ),
                  if (driver.tripActive)
                    Marker(
                      key: ValueKey('ripple_${driver.pingSignal}'),
                      point: LatLng(driver.currentLat!, driver.currentLng!),
                      width: 80,
                      height: 80,
                      child: const _PingRipple(),
                    ),
                  ...driver.halts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final halt = entry.value;
                    if (halt.latitude == null || halt.longitude == null) return null;
                    
                    final isCompleted = index <= maxCompletedIndex;
                    
                    if (isCompleted) {
                      return Marker(
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
                      );
                    } else if (halt.id == nextHalt?.id) {
                      return Marker(
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
                                    color: Theme.of(context).colorScheme.surface,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Marker(
                        point: LatLng(halt.latitude!, halt.longitude!),
                        width: 28,
                        height: 36,
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      );
                    }
                  }).whereType<Marker>(),
                ],
              ),
          ],
        ),
        if (driver.tripActive)
          Positioned(top: 8, right: 8, child: _StatusBadge(driver: driver)),
        if (driver.lastPing != null)
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
                '${driver.lastPing!.hour.toString().padLeft(2, '0')}:${driver.lastPing!.minute.toString().padLeft(2, '0')}:${driver.lastPing!.second.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        if (driver.tripActive)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom + 80,
            child: _NextHaltBanner(driver: driver),
          ),
      ],
    );
  }
}

class _NextHaltBanner extends StatelessWidget {
  final DriverProvider driver;
  const _NextHaltBanner({required this.driver});

  @override
  Widget build(BuildContext context) {
    final halts = driver.halts;
    final nextHalt = halts.isNotEmpty
        ? halts.where((h) => !driver.completedHalts.contains(h.id)).firstOrNull
        : null;

    if (nextHalt == null) {
      if (!driver.tripActive) return const SizedBox.shrink();
      
      return SlideToEnd(
        onComplete: () {
          driver.stopTrip();
        },
      ).animate().fadeIn().slideY(begin: 0.5, curve: Curves.easeOut);
    }

    return FrostedCard(
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

class _StatusBadge extends StatelessWidget {
  final DriverProvider driver;
  const _StatusBadge({required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiary,
            colorScheme.tertiary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(alpha: 0.3),
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
            'LIVE',
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
