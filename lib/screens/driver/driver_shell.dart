import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../profile_screen.dart';
import '../../widgets/squishy_button.dart';

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

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  final MapController _mapController = MapController();
  bool _centeredOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final driver = context.read<DriverProvider>();
      final auth = context.read<AuthProvider>();
      driver.initGps();
      await driver.loadRoutes(auth.currentUser!.id);
      await driver.resumeActiveTrip(auth.currentUser!.id);
      if (driver.resumed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip restored'),
          ),
        );
      }
    });
  }

  void _confirmStopTrip(DriverProvider driver) {
    final completed = driver.completedHalts.length;
    final total = driver.halts.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End trip?'),
        content: Text('$completed of $total halts completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              driver.stopTrip();
            },
            child: const Text('End trip'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();

    if (driver.currentLat != null && !_centeredOnce) {
      _centeredOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(driver.currentLat!, driver.currentLng!), 16);
      });
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.selectedRouteName ?? 'Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
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
          _buildBottomPanel(driver, theme),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(DriverProvider driver, ThemeData theme) {
    final completed = driver.completedHalts.length;
    final total = driver.halts.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.48,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(),
            if (driver.routes.isEmpty)
              _EmptyState(driver: driver, theme: theme)
            else ...[
              _TripHeader(
                driver: driver,
                theme: theme,
                completed: completed,
                total: total,
                progress: progress,
              ),
              if (driver.halts.isNotEmpty) ...[
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: driver.halts.map((halt) {
                      final done = driver.completedHalts.contains(halt.id);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: done
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFFD700).withValues(alpha: 0.3),
                            child: done
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : Text(
                                    '${halt.stopOrder + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: done ? Colors.white : null,
                                    ),
                                  ),
                          ),
                          title: Text(halt.name, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            'Arrival: ${halt.arrivalTime}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: done
                              ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22)
                              : const Icon(Icons.radio_button_unchecked, color: Color(0xFFFFD700), size: 22),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              _TripButton(driver: driver, theme: theme, onStop: () => _confirmStopTrip(driver)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
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
    final isLive = driver.tripActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFF4CAF50) : Colors.black54,
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
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isLive ? 'TRIP ACTIVE' : 'GPS ONLY',
            style: const TextStyle(
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

class _TripHeader extends StatelessWidget {
  final DriverProvider driver;
  final ThemeData theme;
  final int completed;
  final int total;
  final double progress;

  const _TripHeader({
    required this.driver,
    required this.theme,
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          if (driver.routes.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select route',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: driver.routes
                    .map((r) => DropdownMenuItem(
                          value: r['id'] as String,
                          child: Text(r['name'] as String),
                        ))
                    .toList(),
                onChanged: driver.tripActive ? null : (v) {
                  if (v != null) driver.selectRoute(v);
                },
              ),
            ),
          if (total > 0) ...[
            Row(
              children: [
                Text(
                  '$completed of $total halts',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 ? const Color(0xFF4CAF50) : const Color(0xFFFFD700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TripButton extends StatelessWidget {
  final DriverProvider driver;
  final ThemeData theme;
  final VoidCallback onStop;

  const _TripButton({
    required this.driver,
    required this.theme,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!driver.gpsReady && !driver.tripActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gps_off, size: 14, color: Color(0xFFFF5252)),
                  const SizedBox(width: 4),
                  Text(
                    'Enable GPS to start a trip',
                    style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
                  ),
                ],
              ),
            ),
          SquishyButton(
            label: driver.tripActive ? 'STOP TRIP' : 'START TRIP',
            backgroundColor: driver.tripActive
                ? const Color(0xFFFF5252)
                : const Color(0xFFFFD700),
            foregroundColor: const Color(0xFF1E1E1E),
            onTap: driver.selectedRouteId == null || !driver.gpsReady
                ? null
                : () {
                    if (driver.tripActive) {
                      onStop();
                    } else {
                      driver.startTrip(
                        context.read<AuthProvider>().currentUser!.id,
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final DriverProvider driver;
  final ThemeData theme;
  const _EmptyState({required this.driver, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.badge_outlined,
            size: 56,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No route assigned',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask an admin to assign a route to your account.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
