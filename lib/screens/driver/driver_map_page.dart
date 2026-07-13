import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/driver_provider.dart';

class DriverMapPage extends StatefulWidget {
  final Halt? focusHalt;
  const DriverMapPage({super.key, this.focusHalt});

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  final MapController _mapController = MapController();
  bool _centeredOnce = false;

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
            if (driver.currentLat != null && driver.currentLng != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(driver.currentLat!, driver.currentLng!),
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.directions_bus,
                      color: theme.colorScheme.primary,
                      size: 36,
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
                  for (final halt in driver.halts)
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
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: driver.completedHalts.contains(halt.id)
                                    ? const Color(0xFF4CAF50)
                                    : Colors.black87,
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
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFFFF5252),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
          ],
        ),
        if (driver.tripActive)
          Positioned(
            top: 8,
            right: 8,
            child: _StatusBadge(driver: driver),
          ),
        if (driver.lastPing != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${driver.lastPing!.hour.toString().padLeft(2, '0')}:${driver.lastPing!.minute.toString().padLeft(2, '0')}:${driver.lastPing!.second.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
      ],
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
    _scale = Tween<double>(begin: 0.3, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fade = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
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
